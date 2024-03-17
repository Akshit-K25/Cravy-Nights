import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'mongodb.dart';
import 'status.dart';
import 'package:mongo_dart/mongo_dart.dart' show Db;

class RedirectPage extends StatefulWidget {
  final double totalAmount;
  final List<String> selectedItems;
  final Map<String, int> orderQuantities;
  final String email;

  RedirectPage({
    required this.totalAmount,
    required this.selectedItems,
    required this.orderQuantities,
    required this.email,
  });

  @override
  _RedirectPageState createState() => _RedirectPageState();
}

class _RedirectPageState extends State<RedirectPage> {
  bool _isButtonClicked = false;
  bool _isStatusButtonActivated = false;
  bool _isLoading = false;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool hasInternet = true;
  String randomLetter = '';
  int? orderNumber;
  String? token;
  bool paymentSuccessful = false; // Added state variable

  @override
  void initState() {
    super.initState();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
          setState(() {
            hasInternet = result != ConnectivityResult.none;
          });
        });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _generateRandomLetter() async {
    if (_isButtonClicked || !hasInternet) return;

    setState(() {
      _isLoading = true;
    });

    final random = Random();
    final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final randomLetter = alphabet[random.nextInt(alphabet.length)];

    var db = await Db.create(MONGO_URL);
    await db.open();

    await MongoDatabase.initializeLock(db);

    print('Attempting to acquire lock...');
    final lock = await MongoDatabase.acquireLock(db);

    if (lock) {
      print('Lock acquired.');
      orderNumber = await MongoDatabase.getNextOrderNumber();

      if (orderNumber != null) {
        setState(() {
          token = '$randomLetter$orderNumber';
          _isButtonClicked = true;
          _isStatusButtonActivated = true;
          _isLoading = false;
          paymentSuccessful = true; // Update payment status
        });

        print('Generated Token: $token');

        if (hasInternet) {
          final order = Order(
            quantities: widget.orderQuantities,
            totalAmount: widget.totalAmount,
            orderDate: DateTime.now(),
            token: token!,
            email: widget.email,
          );

          final result = await MongoDatabase.saveOrder(order);
          if (result) {
            print('Order saved successfully');
          } else {
            print('Failed to save order');
          }
        }
      } else {
        print('Failed to fetch order number');
      }

      print('Releasing lock...');
      await MongoDatabase.releaseLock(db);
      print('Lock released.');
    } else {
      print('Failed to acquire lock');
    }

    await db.close();
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('No internet!'),
          content: Text('Check your connection and try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFF1D0E58),
        body: Stack(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(1200),
                ),
                color: Color(0xFFE1E1E5),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 4,
                decoration: BoxDecoration(
                  color: Color(0xFFE1E1E5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(1200),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isButtonClicked && token == null)
                    CircularProgressIndicator(),
                  if (token != null)
                    Text(
                      '$token',
                      style: TextStyle(
                        fontSize: 90,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE1E1E5),
                      ),
                    ),
                  SizedBox(height: 20),
                  Text(
                    paymentSuccessful // Updated condition here
                        ? 'Enjoy your meal!!' // Updated text here
                        : hasInternet
                        ? 'Your payment was successful.'
                        : 'No internet!',
                    style: TextStyle(
                      fontSize: 24,
                      color: Color(0xFFE1E1E5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isButtonClicked || !hasInternet
                        ? null
                        : () {
                      _generateRandomLetter();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE1E1E5),
                      foregroundColor: Color(0xFF1D0E58),
                    ),
                    child: Text(
                        hasInternet ? 'Generate Token' : 'Retry'),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isStatusButtonActivated
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatusPage(
                            email: widget.email,
                          ),
                        ),
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE1E1E5),
                      foregroundColor: Color(0xFF1D0E58),
                    ),
                    child: Text('Status'),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.yellowAccent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}