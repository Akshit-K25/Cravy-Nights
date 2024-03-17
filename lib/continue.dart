import 'dart:async'; // Importing Timer class
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'redirect.dart';
import 'mongodb.dart';

class ContinuePage extends StatefulWidget {
  final Set<String> cancelledItems = {};
  final double totalAmount;
  final List<String> selectedItems;
  final Map<String, int> orderQuantities;
  final Map<String, double> menuItems;
  final String email;

  ContinuePage({
    required this.totalAmount,
    required this.selectedItems,
    required this.orderQuantities,
    required this.menuItems,
    required this.email,
  });

  @override
  _ContinuePageState createState() => _ContinuePageState();
}

class _ContinuePageState extends State<ContinuePage> {
  final Razorpay _razorpay = Razorpay();
  late Timer _timer;
  bool _isPaymentProcessing = false;

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimeout() {
    const duration = const Duration(seconds: 45);
    _timer = Timer(duration, () {
      Navigator.pop(context);
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _timer.cancel();
    print("Payment Successful: ${response.paymentId}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RedirectPage(
          totalAmount: widget.totalAmount,
          selectedItems: widget.selectedItems,
          orderQuantities: widget.orderQuantities,
          email: widget.email,
        ),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _timer.cancel();
    print("Payment Error: ${response.code} - ${response.message}");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Error"),
          content: Text("Your payment was cancelled."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handlePaymentCancellation();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  void startPayment(double amount) async {
    setState(() {
      _isPaymentProcessing = true;
    });

    bool itemsAvailable = await lockSelectedItems();
    if (itemsAvailable) {
      var options = {
        'key': 'rzp_live_RsdszxKGLQsaoB',
        'amount': amount * 100,
        'name': 'Night Canteen',
        'description': 'Payment for selected items',
        'prefill': {'contact': '9347572857', 'email': 'akshit2518@gmail.com'},
        'external': {
          'wallets': ['paytm']
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        print("Error while starting Razorpay payment: $e");
        setState(() {
          _isPaymentProcessing = false;
        });
      }
    } else {
      print("Selected items not available for purchase");
      setState(() {
        _isPaymentProcessing = false;
      });
    }
  }

  void _handlePaymentCancellation() {
    unlockCancelledItems(widget.cancelledItems.toList());
    widget.cancelledItems.clear();
  }

  @override
  Widget build(BuildContext context) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(1200),
              ),
              color: Color(0xFF1D0E58),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 3.5,
              decoration: BoxDecoration(
                color: Color(0xFF1D0E58),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(1200),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_rounded,
                    size: 40,
                    color: Color(0xFFE1E1E5),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Selected Items',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE1E1E5),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 20, bottom: 20),
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Color(0xFFE1E1E5),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 7,
                        spreadRadius: 0,
                        offset: Offset(5, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DataTable(
                      columnSpacing: 20,
                      columns: [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Amount')),
                      ],
                      rows: widget.selectedItems
                          .where((item) => widget.orderQuantities[item]! > 0)
                          .map((item) {
                        final quantity = widget.orderQuantities[item];
                        final amount = widget.menuItems[item]! * quantity!;
                        return DataRow(cells: [
                          DataCell(Text(item)),
                          DataCell(Text(quantity.toString())),
                          DataCell(Text('${amount.toStringAsFixed(2)} rupees')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              margin: EdgeInsets.only(bottom: 20),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFE1E1E5),
                shape: BoxShape.circle,
              ),
              child: Transform.rotate(
                angle: 90 * 3.1415926535 / 180, // 90 degrees anticlockwise in radians
                child: IconButton(
                  icon: Icon(Icons.u_turn_left_rounded, color: Color(0xFF1D0E58)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Amount: ${widget.totalAmount} rupees',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFe1e1e5),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: ElevatedButton(
                    onPressed: _isPaymentProcessing ? null : () {
                      startPayment(widget.totalAmount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE1E1E5),
                      foregroundColor: Color(0xFF1D0E58),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      'Pay Now',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> lockSelectedItems() async {
    bool allItemsAvailable = true;
    for (var entry in widget.orderQuantities.entries) {
      var itemName = entry.key;
      var quantity = entry.value;
      var itemStock = await MongoDatabase.getItemStock(itemName);
      if (itemStock - (MongoDatabase.lockedQuantities[itemName] ?? 0) < quantity) {
        allItemsAvailable = false;
        break;
      }
    }
    if (allItemsAvailable) {
      for (var entry in widget.orderQuantities.entries) {
        var itemName = entry.key;
        var quantity = entry.value;
        await MongoDatabase.lockStock(itemName, quantity);
      }
    }
    return allItemsAvailable;
  }

  void unlockCancelledItems(List<String> cancelledItems) {
    for (var cancelledItem in cancelledItems) {
      if (!widget.cancelledItems.contains(cancelledItem)) {
        if (MongoDatabase.lockedQuantities.containsKey(cancelledItem)) {
          var quantity = MongoDatabase.lockedQuantities[cancelledItem];
          if (quantity != null) {
            MongoDatabase.unlockStock(cancelledItem, quantity);
          }
        }
        widget.cancelledItems.add(cancelledItem);
      }
    }
  }
}