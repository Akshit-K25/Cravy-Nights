import 'package:flutter/material.dart';
import 'razorpay.dart';
import 'mongodb.dart';


class PaymentPage extends StatelessWidget {
  static const String routeName = '/payment';
  final double totalAmount;
  final List<String> selectedItems;
  final Map<String, int> orderQuantities;
  final Map<String, double> menuItems;
  final String email;

  PaymentPage({
    required this.totalAmount,
    required this.selectedItems,
    required this.orderQuantities,
    required this.menuItems,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final double totalAmount = args['totalAmount'];
    final List<String> selectedItems = args['selectedItems'];
    final Map<String, int> orderQuantities = args['orderQuantities'];
    final Map<String, double> menuItems = args['menuItems'];
    final String userEmail = args['email'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Page',
          style: TextStyle(color: Colors.white),
      ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[Colors.deepOrange, Colors.indigo],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            DataTable(
              columns: [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Quantity')),
                DataColumn(label: Text('Amount')),
              ],
              rows: selectedItems
                  .where((item) => orderQuantities[item]! > 0)
                  .map((item) {
                final quantity = orderQuantities[item];
                final amount = menuItems[item]! * quantity!;
                return DataRow(cells: [
                  DataCell(Text(item)),
                  DataCell(Text(quantity.toString())),
                  DataCell(Text('${amount.toStringAsFixed(2)} rupees')),
                ]);
              }).toList(),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Center(
                    child: Text(
                      'Total Amount: $totalAmount rupees',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      // Check if no items are selected
                      if (selectedItems.isEmpty) {
                        // Show pop-up message
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              title: Text('No Items Selected'),
                              content: Text('Please select items before proceeding to payment.'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        // Generate order number here
                        int orderNumber = await MongoDatabase.getNextOrderNumber();
                        // Navigate to the Razorpay payment screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RazorpayPaymentScreen(
                              totalAmount: totalAmount,
                              selectedItems: selectedItems,
                              orderQuantities: orderQuantities,
                              orderNumber: orderNumber,
                              email: email,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      'Pay Now',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}