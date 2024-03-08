import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:classico/mongodb.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'login.dart';
import 'token.dart';

class RazorpayPaymentScreen extends StatefulWidget {
  final double totalAmount;
  final List<String> selectedItems;
  final Map<String, int> orderQuantities;
  final int orderNumber;
  final String email;

  RazorpayPaymentScreen({
    required this.totalAmount,
    required this.selectedItems,
    required this.orderQuantities,
    required this.orderNumber,
    required this.email,
  });

  @override
  _RazorpayPaymentScreenState createState() => _RazorpayPaymentScreenState();
}

class _RazorpayPaymentScreenState extends State<RazorpayPaymentScreen> {
  bool _isLoading = false;
  bool _paymentSuccess = false;
  Razorpay _razorpay = Razorpay();
  int _retryCount = 0;
  static const int _maxRetryCount = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  String? _token;

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        // Handle no internet connection
        // Optionally, you can show a message or disable certain features
      } else {
        // Handle internet connection restored
        // Refresh the state of your app as needed
      }
    });
  }

  void _navigateToTokenPageIfNeeded() {
    if (_paymentSuccess) {
      Navigator.popUntil(context, ModalRoute.withName('/payment_page'));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TokenPage(token: "")),
      );
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _cancelPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment process canceled. Please try again.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    bool mounted = true;

    try {
      setState(() {
        _isLoading = true;
      });

      _token = await _generateTokenWithRetry(widget.orderNumber); // Use retry mechanism to generate token

      // Filter out items with quantity 0
      Map<String, int> filteredOrderQuantities = {};
      widget.orderQuantities.forEach((itemName, quantity) {
        if (quantity > 0) {
          filteredOrderQuantities[itemName] = quantity;
        }
      });

      bool orderSaved = await performDatabaseOperationWithRetry(() {
        return MongoDatabase.saveOrder(Order(
          quantities: filteredOrderQuantities,
          totalAmount: widget.totalAmount,
          orderDate: DateTime.now(),
          email: widget.email, // Use the email passed from the LoginPage
          token: _token!, // Ensure _token is not null
        ));
      });

      if (orderSaved) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _paymentSuccess = true;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order placed successfully!'),
          duration: Duration(seconds: 2),
        ));
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _paymentSuccess = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to place order. Please try again later.'),
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      print('Error handling payment success: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _paymentSuccess = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      await _unlockStocks();

      // Check if the connection is restored and generate the token if it is
      Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        if (result != ConnectivityResult.none) {
          _generateTokenWithRetry(widget.orderNumber).then((token) {
            if (mounted) {
              setState(() {
                _token = token;
              });
            }
          });
        }
      });
    }
  }

  Future<String> _generateTokenWithRetry(int orderNumber) async {
    for (int i = 0; i < _maxRetryCount; i++) {
      try {
        String token = await _generateTokenNumber(orderNumber);
        return token;
      } catch (e) {
        print('Error generating token: $e');
        await Future.delayed(_retryDelay);
      }
    }
    throw Exception('Unable to generate token after $_maxRetryCount attempts');
  }

  Future<void> _retryDatabaseOperation(Order order) async {
    for (int i = 0; i < _maxRetryCount; i++) {
      try {
        // Attempt the database operation
        await MongoDatabase.saveOrder(order);
        return;
      } catch (e) {
        print('Error performing database operation: $e');
        await Future.delayed(_retryDelay);
      }
    }
    print('Max retry count reached. Unable to perform database operation.');
  }

  Future<T> performDatabaseOperationWithRetry<T>(Future<T> Function() operation) async {
    T result;
    for (int i = 0; i <= _maxRetryCount; i++) {
      try {
        result = await operation();
        return result;
      } catch (e) {
        if (i == _maxRetryCount) {
          rethrow;
        }
        print('Error: $e, Retrying in $_retryDelay');
        await Future.delayed(_retryDelay);
      }
    }
    throw Exception('Operation failed after $_maxRetryCount attempts');
  }

  void _showRetryDialog(String token, PaymentSuccessResponse response, Function retryCallback) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Network Issue"),
          content: Text("Failed to generate token due to lost internet connection."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                retryCallback(); // Retry generating the order
              },
              child: Text("Retry"),
            ),
          ],
        );
      },
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    setState(() {
      _isLoading = false;
    });
    // Unlock stock for items in the order
    await _unlockStocks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed. Please try again.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _generateTokenNumber(int orderNumber) {
    try {
      String randomLetter = String.fromCharCode(Random().nextInt(26) + 65);
      return '$randomLetter$orderNumber';
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    MongoDatabase.setRetryCallback((order) => _retryDatabaseOperation(order));
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your token will be generated which will be used to take your order after successful payment.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _isLoading ? CircularProgressIndicator() : SizedBox(),
            SizedBox(height: 20),
            Text(
              'Total Amount: ${widget.totalAmount} rupees',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: _isLoading ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: Text('Make Payment'),
            ),
            SizedBox(height: 25),
            ElevatedButton(
              onPressed: _paymentSuccess && _token != null ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TokenPage(token: _token!)),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _paymentSuccess && _token != null ? Colors.purple : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: Text('Generate Token'),
            ),
          ],
        ),
      ),
    );
  }

  void _startPayment() {
    const paymentTimeoutDuration = Duration(minutes: 5);
    Timer? paymentTimeoutTimer;

    paymentTimeoutTimer = Timer(paymentTimeoutDuration, () {
      paymentTimeoutTimer?.cancel();
      _cancelPayment();
    });

    MongoDatabase.getStock().then((currentStock) {
      bool allItemsAvailable = true;
      Future.forEach(widget.selectedItems, (itemName) async {
        if (currentStock.containsKey(itemName) &&
            (currentStock[itemName] as int ?? 0) >=
                (widget.orderQuantities[itemName] ?? 0)) {
          bool success = await MongoDatabase.lockStock(
              itemName, widget.orderQuantities[itemName] ?? 0);
          if (!success) {
            allItemsAvailable = false;
          }
        } else {
          allItemsAvailable = false;
        }
      }).then((_) {
        if (!allItemsAvailable) {
          paymentTimeoutTimer?.cancel();
          _cancelPayment();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Some items in your order are out of stock.'),
            duration: Duration(seconds: 2),
          ));
          return;
        }

        var options = {
          'key': 'rzp_live_RsdszxKGLQsaoB',
          'amount': (widget.totalAmount * 100).round(),
          'name': 'Night Canteen',
          'description': 'Payment for selected items',
          'prefill': {
            'contact': '9347572857',
            'email': 'akshit2518@gmail.com',
          },
          'external': {
            'wallets': ['paytm'],
          },
        };
        _razorpay.open(options);
      });
    }).catchError((e) {
      print("Error in initiating payment: $e");
    });
  }

  Future<void> _unlockStocks() async {
    try {
      for (String itemName in widget.selectedItems) {
        await MongoDatabase.unlockStock(itemName, widget.orderQuantities[itemName] ?? 0);
      }
    } catch (e) {
      print('Error unlocking stocks: $e');
    }
  }
}