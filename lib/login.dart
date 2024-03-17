import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup.dart';
import 'mongodb.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  static const String routeName = '/login';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String userEmail = '';

  Future<void> saveCredentials(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
    // Save the current timestamp
    await prefs.setInt('timestamp', DateTime
        .now()
        .millisecondsSinceEpoch);
  }

  Future<void> loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email') ?? '';
    String password = prefs.getString('password') ?? '';
    int timestamp = prefs.getInt('timestamp') ?? 0;
    // Check if stored credentials are within a week
    if (email.isNotEmpty &&
        password.isNotEmpty &&
        DateTime
            .now()
            .difference(DateTime.fromMillisecondsSinceEpoch(timestamp))
            .inDays <= 7) {
      emailController.text = email;
      passwordController.text = password;
    }
  }

  Future<bool> validateLogin(String email, String password) async {
    await Future.delayed(Duration(seconds: 2));
    bool isValidLogin = await MongoDatabase.validateUser(email, password);
    if (isValidLogin) {
      setState(() {
        userEmail = email;
      });
      await saveCredentials(email, password);
    }
    return isValidLogin;
  }

  @override
  void initState() {
    super.initState();
    loadCredentials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1D0E58),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 10),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/App_Icon.jpg'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  SizedBox(height: 10), // Adjusted height
                  Text(
                    'Cravy Nights',
                    style: TextStyle(
                      fontSize: 28, // Increased font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 50), // Adjusted height
                  Container(
                    width: 300,
                    padding: EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Color(0xFFE1E1E5),
                      borderRadius: BorderRadius.circular(40.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 28, // Increased font size
                            color: Color(0xFF1D0E58),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 50),
                        _buildTextFieldWithLabel('Email', emailController),
                        SizedBox(height: 25),
                        _buildTextFieldWithLabel(
                            'Password', passwordController, obscureText: true),
                        SizedBox(height: 25),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, SignupPage.routeName);
                          },
                          child: Text(
                              'Not a user? Sign-up', style: TextStyle(color: Color(
                              0xFF1D0E58))), // Text color set to blue
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              isLoading = true;
                            });
                            String email = emailController.text;
                            String password = passwordController.text;
                            bool isValidLogin = await validateLogin(
                                email, password);
                            setState(() {
                              isLoading = false;
                            });
                            if (isValidLogin) {
                              Navigator.pushNamed(
                                context,
                                MyNightCanteenScreen.routeName,
                                arguments: {'email': userEmail},
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Color(0xFFE1E1E5),
                                    content: Container(
                                      width: 350, // Keeping the width as 350
                                      height: 260, // Keeping the height as 260
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text('Invalid Credentials',
                                              style: TextStyle(fontSize: 30)),
                                          SizedBox(height: 20),
                                          Text(
                                              'Please enter valid email and password.',
                                              textAlign: TextAlign.left),
                                          Spacer(),
                                          // Add spacer to push button to the bottom
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Container(
                                              width: 120, // Adjusted button width
                                              child: TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Color(
                                                      0xFF1D0E58),
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 12.0,
                                                      horizontal: 24.0),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius
                                                        .circular(30.0),
                                                  ),
                                                ),
                                                child: Text(
                                                  'OK',
                                                  style: TextStyle(
                                                      color: Color(0xFFE1E1E5)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1D0E58),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  40.0), // Increased border radius
                            ),
                          ),
                          child: Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
          isLoading
              ? Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(
                // Setting the valueColor property to green
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
              ), // Loading indicator
            ),
          )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildTextFieldWithLabel(String label,
      TextEditingController controller, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF1D0E58),
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 5),
        Material(
          elevation: 6, // Adjust the elevation to control the shadow
          borderRadius: BorderRadius.circular(30.0),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                  vertical: 10.0, horizontal: 15.0),
              // Adjusted vertical padding
              filled: true,
              fillColor: Color(0xFFD9D9D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none, // Remove border outline
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none, // Remove border outline
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none, // Remove border outline
              ),
            ),
          ),
        ),
      ],
    );
  }
}