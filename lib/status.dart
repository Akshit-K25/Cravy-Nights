import 'package:flutter/material.dart';
import 'mongodb.dart';
import 'main.dart';

class StatusPage extends StatefulWidget {
  static const String routeName = '/status';
  final String email;

  StatusPage({required this.email});

  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  late Future<List<Map<String, dynamic>>> futureOrders;

  @override
  void initState() {
    super.initState();
    futureOrders = MongoDatabase.fetchOrders(widget.email);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popUntil(
          context,
          ModalRoute.withName('/main'),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFE1E1E5), // Set scaffold background color
        body: RefreshIndicator(
          onRefresh: _refreshOrders,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: futureOrders,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else {
                var ordersData = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: ordersData.length,
                  itemBuilder: (context, index) {
                    var orderData = ordersData[index];
                    var quantities = (orderData['quantities'] ?? {}) as Map<String, dynamic>;
                    var totalAmount = orderData['totalAmount'] as double;
                    var token = orderData['token'] as String;
                    var status = orderData['status'] as bool;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Material(
                        elevation: 5, // Set elevation for the shadow
                        borderRadius: BorderRadius.circular(20.0),
                        child: InkWell(
                          onTap: () {
                            print('Quantities before calling _showOrderPopup: $quantities');
                            _showOrderPopup(context, token, quantities, totalAmount, status);
                          },
                          child: Container(
                            width: 200,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Color(0xFFD9D9D9), // Set box color
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 50.0), // Add padding to the left side
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Token',
                                          style: TextStyle(color: Color(0xFF1D0E58), fontSize: 12.0),
                                        ),
                                        SizedBox(height: 4.0),
                                        Text(
                                          token,
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 70.0),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Total',
                                        style: TextStyle(color: Color(0xFF1D0E58), fontSize: 12.0),
                                      ),
                                      SizedBox(height: 4.0),
                                      Text(
                                        totalAmount.toString(),
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF1D0E58),
                                  size: 35,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: Color(0xFFE1E1E5),
            elevation: 0.0,
            automaticallyImplyLeading: false,
            title: Container(
              margin: EdgeInsets.only(left: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Color(0xFF1D0E58),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Color(0xFFE1E1E5),
                      ),
                    ),
                  ),
                  SizedBox(width: 25.0),
                  Text(
                    'MY ORDERS',
                    style: TextStyle(
                      color: Color(0xFF1D0E58),
                      fontSize: 25.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderPopup(
      BuildContext context,
      String token,
      Map<String, dynamic>? quantities,
      double totalAmount,
      bool status,
      ) {
    print('Showing order popup!');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFD9D9D9), // Set background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          title: Text('Order Details',
          style: TextStyle(fontSize: 32, color: Color(0xFF1D0E58)),
          ),
          content: Container(
            width: 350,
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 35),
                Text(
                  'Token: $token',
                  style: TextStyle(fontSize: 16, color: Color(0xFF1D0E58)),
                ),
                SizedBox(height: 8.0), // Adding SizedBox between Token and other details
                if (quantities != null && quantities.isNotEmpty)
                  Text(
                    'Quantities: ${quantities.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                    style: TextStyle(fontSize: 16, color: Color(0xFF1D0E58)),
                  ),
                SizedBox(height: 30.0),
                Text(
                  'Total Amount: ${totalAmount.toString()}',
                  style: TextStyle(fontSize: 16, color: Color(0xFF1D0E58)),
                ),
                SizedBox(height: 30.0),
                Row(
                  children: [
                    Text(
                      status ? 'Order Status: Ready!!' : 'Order Status: Waiting',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: status ? Color(0xFF078F1D) : Color(0xFFCD1818),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    if (status)
                      Icon(Icons.check_circle, color: Color(0xFF078F1D))
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1D0E58),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _refreshOrders();
                      },
                      child: Text(
                        'Retry',
                        style: TextStyle(fontSize: 16, color: Color(0xFFE1E1E5)),
                      ),
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1D0E58),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(fontSize: 16, color: Color(0xFFE1E1E5)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshOrders() async {
    setState(() {
      futureOrders = MongoDatabase.fetchOrders(widget.email);
    });
  }
}