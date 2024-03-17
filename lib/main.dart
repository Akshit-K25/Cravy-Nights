import 'package:flutter/material.dart';
import 'mongodb.dart';
import 'continue.dart';
import 'splash_screen.dart';
import 'login.dart';
import 'signup.dart';
import 'status.dart'; // Import status.dart for My Orders page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        StatusPage.routeName: (context) {
          final String email =
          ModalRoute.of(context)!.settings.arguments as String;
          return StatusPage(email: email);
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
  _MyNightCanteenScreenState createState() =>
      _MyNightCanteenScreenState(userEmail: userEmail);
}

class _MyNightCanteenScreenState extends State<MyNightCanteenScreen> {
  late final String userEmail;
  TextEditingController searchController = TextEditingController();
  late String searchQuery = '';

  _MyNightCanteenScreenState({required this.userEmail});

  bool _backButtonPressed = false;

  Map<String, double> menuItems = {};
  Map<String, int> menuItemsStock = {};
  Map<String, int> orderQuantities = {};

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    fetchMenuItems();
    fetchMenuItemsStock();
    searchController.addListener(onSearchChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged() {
    setState(() {
      searchQuery = searchController.text.toLowerCase();
    });
  }

  Future<void> fetchMenuItems() async {
    try {
      List<Map<String, dynamic>> items =
      await MongoDatabase.getItemsFromMongoDB();
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
      List<Map<String, dynamic>> items =
      await MongoDatabase.getItemsFromMongoDB();
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
        total += itemPrice * quantity;
      }
    });
    return total;
  }

  void _navigateToContinuePage(String email) {
    if (getTotalPrice() == 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('No Items Selected'),
            content: Text('You have not selected any items to continue.'),
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
    } else if (orderQuantities.entries.any((entry) => entry.value > menuItemsStock[entry.key]!)) {
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContinuePage(
            totalAmount: getTotalPrice(),
            selectedItems: orderQuantities.keys.toList(),
            orderQuantities: orderQuantities,
            menuItems: menuItems,
            email: email, // Provide the 'email' parameter
          ),
        ),
      );
    }
  }

  Widget buildMenuItemContainer(
      Map<String, double> menuItems,
      Map<String, int> orderQuantities,
      Map<String, int> menuItemsStock,
      String item,
      ) {
    final price = menuItems[item];

    // Check if the image file exists in the specified directory
    String imagePath = 'assets/images/CRCL/$item.jpg';
    bool imageExists = AssetImage(imagePath).assetName != null;

    return Container(
      width: 160.0,
      height: 215.0,
      margin: EdgeInsets.only(bottom: 20.0), // Adding bottom margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(2.0, 2.0),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 8), // Top padding
          // Display image if it exists, otherwise show placeholder text
          imageExists
              ? Container(
            height: 119,
            width: 132,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(25.0),
            ),
          )
              : Text(
            'No image',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              item,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${price?.toStringAsFixed(2) ?? 'N/A'} rupees',
            style: TextStyle(fontSize: 16),
          ),
          Expanded(
            child: SizedBox(
              height: 50.0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (orderQuantities[item] != null &&
                                  orderQuantities[item]! > 0) {
                                orderQuantities[item] =
                                    orderQuantities[item]! - 1;
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
                              if (orderQuantities[item] == null ||
                                  orderQuantities[item]! <
                                      menuItemsStock[item]!) {
                                orderQuantities[item] =
                                    (orderQuantities[item] ?? 0) + 1;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 8), // Bottom padding
        ],
      ),
    );
  }

  List<String> getFilteredItems() {
    if (searchQuery.isEmpty) {
      return menuItems.keys.toList();
    } else {
      return menuItems.keys
          .where((item) => item.toLowerCase().contains(searchQuery))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return true if you want to allow back navigation, false otherwise
        if (_backButtonPressed) {
          // If back button is pressed again, exit the app
          return true;
        } else {
          // If back button is pressed for the first time, set the flag to true
          _backButtonPressed = true;
          // Show a snackbar or toast message indicating what will happen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Press back again to exit"),
              duration: Duration(seconds: 2),
            ),
          );
          // Return false to prevent default back navigation
          return false;
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        body: RefreshIndicator(
          onRefresh: () async {
            await fetchMenuItems();
            await fetchMenuItemsStock();
          },
          child: Container(
            color: Color(0xFFE1E1E5),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30), // Add space from top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40.0,
                        height: 41.2,
                        margin: EdgeInsets.only(left: 20.0), // Adjust margin as needed
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          image: DecorationImage(
                            image: AssetImage('assets/images/App_Icon.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        'Feast Your Senses: \nDive into Delicious Delights!',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF304250),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 2.0),
                        child: Container(
                          height: 50,
                          width: 50,
                          child: IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.black,
                              size: 30,
                            ),
                            onPressed: () {
                              _scaffoldKey.currentState!.openEndDrawer();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 35.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45.0,
                            // Add border radius to create rounded corners
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: Offset(0, 2), // Adjust offset as needed
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Search items...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0), // Set border radius here
                                  borderSide: BorderSide.none, // Remove border
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                                suffixIcon: searchController.text.isNotEmpty
                                    ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                  },
                                )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Container(
                          height: 45.0,
                          width: 54.0,
                          // Add shadow to create bottom shadow effect
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1D0E58),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: Offset(0, 2), // Adjust offset as needed
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.search),
                            color: Colors.white,
                            onPressed: () {
                              // Add search functionality here
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 35.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text(
                          'Craves',
                          style: TextStyle(
                            fontSize: 25,
                            color: Color(0xFF304250),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: GridView.count(
                        crossAxisCount: 2, // Set number of columns to 2
                        crossAxisSpacing: 20.0, // Set spacing between columns
                        mainAxisSpacing: 20.0, // Set spacing between rows
                        padding: EdgeInsets.all(16.0),
                        childAspectRatio: 0.55,
                        children: getFilteredItems().map((item) {
                          return buildMenuItemContainer(
                            menuItems,
                            orderQuantities,
                            menuItemsStock,
                            item,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF1D0E58),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          'Total Amount: ${getTotalPrice().toStringAsFixed(2)} rupees',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      GestureDetector(
                        onTap: getTotalPrice() > 0 ? () => _navigateToContinuePage(userEmail) : null,
                        child: Container(
                          height: 40.0,
                          width: 40.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1D0E58),
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        endDrawer: SizedBox(
          width: 210,
          child: Drawer(
            child: Container(
              color: Color(0xFFE1E1E5),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 90, bottom: 10),
                    child: Container(
                      height: 122, // Set the height to 122
                      margin: EdgeInsets.symmetric(horizontal: 20), // Adjust the margin as needed
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/App_Icon_Clear.png'), // Replace 'path_to_your_image' with the path to your image asset
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'C.R.C.L',
                    style: TextStyle(
                      color: Color(0xFF1D0E58),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 25),
                    leading: Icon(Icons.shopping_cart_rounded, color: Color(0xFF1D0E58)),
                    title: Text(
                        'My Orders',
                      style: TextStyle(
                        color: Color(0xFF1D0E58),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, StatusPage.routeName, arguments: userEmail);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 25),
                    leading: Icon(Icons.logout, color: Color(0xFF1D0E58)),
                    title: Text(
                        'Logout',
                      style: TextStyle(
                        color: Color(0xFF1D0E58),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, LoginPage.routeName);
                    },
                  ),
                  SizedBox(height: 370),
                  Text(
                    'By Cravy Nights',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D0E58),
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
}