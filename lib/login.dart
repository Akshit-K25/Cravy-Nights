import 'package:flutter/material.dart';
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

  Future<bool> validateLogin(String email, String password) async {
    await Future.delayed(Duration(seconds: 2));
    bool isValidLogin = await MongoDatabase.validateUser(email, password);
    if (isValidLogin) {
      setState(() {
        userEmail = email;
      });
    }
    return isValidLogin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 300,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, SignupPage.routeName);
                    },
                    child: Text('Not a user? Sign-up'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      String email = emailController.text;
                      String password = passwordController.text;
                      bool isValidLogin = await validateLogin(email, password);
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
                              title: Text('Invalid Credentials'),
                              content: Text('Please enter valid email and password.'),
                              actions: [
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
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: Text('Login'),
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ), // Loading indicator
            ),
          )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
