import 'package:flutter/material.dart';
import 'mongodb.dart';
import 'payment_page.dart';
import 'splash_screen.dart';
import 'login.dart';
import 'signup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();;
  runApp(MyNightCanteenApp());
  _initializeAppInBackground();
}

void _initializeAppInBackground() async {
  await MongoDatabase.connect();
}

class MyNightCanteenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        LoginPage.routeName: (context) => LoginPage(),
        SignupPage.routeName: (context) => SignupPage(),
        MyNightCanteenScreen.routeName: (context) {
          final Map<String, dynamic> args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final String email = args['email'];
          return MyNightCanteenScreen(userEmail: email);
        },
        PaymentPage.routeName: (context) {
          final Map<String, dynamic> args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final double totalAmount = args['totalAmount'];
          final List<String> selectedItems = args['selectedItems'];
          final Map<String, int> orderQuantities = args['orderQuantities'];
          final Map<String, double> menuItems = args['menuItems'];
          final String email = args['email'];
          return PaymentPage(
            totalAmount: totalAmount,
            selectedItems: selectedItems,
            orderQuantities: orderQuantities,
            menuItems: menuItems,
            email: email,
          );
        },
      },
    );
  }
}

class MyNightCanteenScreen extends StatefulWidget {
  static const String routeName = '/main';
  
  final String userEmail;

  // Constructor
  MyNightCanteenScreen({required this.userEmail});

  @override
  _MyNightCanteenScreenState createState() => _MyNightCanteenScreenState(userEmail: userEmail);
}

class _MyNightCanteenScreenState extends State<MyNightCanteenScreen> {
  late final String userEmail;

  _MyNightCanteenScreenState({required this.userEmail});

  Map<String, double> menuItems = {};
  Map<String, int> menuItemsStock = {};
  Map<String, int> orderQuantities = {};

  @override
  void initState() {
    super.initState();
    fetchMenuItems();
    fetchMenuItemsStock();
  }

  Future<void> fetchMenuItems() async {
    try {
      List<Map<String, dynamic>> items = await MongoDatabase.getItemsFromMongoDB();
      setState(() {
        menuItems = Map.fromIterable(
          items,
          key: (item) => item['itemName'] as String,
          value: (item) => (item['itemPrice'] as num).toDouble(),
        );
      });
    } catch (e) {
      print('Error fetching menu items: $e');
    }
  }

  Future<void> fetchMenuItemsStock() async {
    try {
      List<Map<String, dynamic>> items = await MongoDatabase.getItemsFromMongoDB();
      setState(() {
        menuItemsStock = Map.fromIterable(
          items,
          key: (item) => item['itemName'] as String,
          value: (item) => item['itemStock'] as int,
        );
      });

      orderQuantities.forEach((item, quantity) {
        if (quantity > menuItemsStock[item]!) {
          setState(() {
            orderQuantities[item] = 0;
          });
        }
      });
    } catch (e) {
      print('Error fetching menu item stocks: $e');
    }
  }

  double getTotalPrice() {
    double total = 0.0;
    orderQuantities.forEach((item, quantity) {
      double? itemPrice = menuItems[item];
      if (itemPrice != null) {
        total += itemPrice * quantity!;
      }
    });
    return total;
  }

  void _navigateToPaymentPage(String email) {
    if (orderQuantities.entries.any((entry) => entry.value > menuItemsStock[entry.key]!)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Out of Stock'),
            content: Text('One or more selected items are out of stock.'),
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
      Navigator.pushNamed(
        context,
        PaymentPage.routeName,
        arguments: {
          'totalAmount': getTotalPrice(),
          'selectedItems': orderQuantities.keys.toList(),
          'orderQuantities': orderQuantities,
          'menuItems': menuItems,
          'email': email,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Night Canteen',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[Colors.indigo, Colors.deepOrange],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchMenuItems();
          await fetchMenuItemsStock();
        },
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/App_bg.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      var item = menuItems.keys.elementAt(index);
                      var price = menuItems[item];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: Offset(2.0, 2.0),
                              blurRadius: 4.0,
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 20.0),
                        child: ListTile(
                          title: Text(item),
                          subtitle: Text(
                            '${price?.toStringAsFixed(2) ?? 'N/A'} rupees',
                            style: TextStyle(fontSize: 16),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (orderQuantities[item] != null && orderQuantities[item]! > 0) {
                                      orderQuantities[item] = orderQuantities[item]! - 1;
                                    }
                                  });
                                },
                              ),
                              Text(
                                '${orderQuantities[item] ?? 0}',
                                style: TextStyle(fontSize: 16),
                              ),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    if (orderQuantities[item] == null || orderQuantities[item]! < menuItemsStock[item]!) {
                                      orderQuantities[item] = (orderQuantities[item] ?? 0) + 1;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    itemExtent: 100.0,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'Total: ${getTotalPrice().toStringAsFixed(2)} rupees',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.0),
                    ElevatedButton(
                      onPressed: () => _navigateToPaymentPage(userEmail),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: StadiumBorder(),
                      ),
                      child: Text('Continue'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}