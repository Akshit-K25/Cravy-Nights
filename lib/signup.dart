import 'package:flutter/material.dart';
import 'mongodb.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  static const String routeName = '/signup';

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isEmailValid = true;
  bool _isEmailUsed = false;
  bool _isLoading = false;

  bool isPasswordValid(String password) {
    if (password.length < 6 || password.length > 12) {
      return false;
    }

    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return false;
    }

    if (!RegExp(r'\d').hasMatch(password)) {
      return false;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return false;
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE1E1E5),
      body: Center(
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
                    image: AssetImage('assets/images/App_Icon_Clear.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Cravy Nights',
                style: TextStyle(
                  fontSize: 28, // Increased font size
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D0E58),
                ),
              ),
              SizedBox(height: 30),
              Container(
                width: 300,
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Color(0xFF1D0E58),
                  borderRadius: BorderRadius.circular(40.0),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Email Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE1E1E5), // Set color to white
                              ),
                            ),
                          ),
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFFE1E1E5),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFD9D9D9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                              isDense: true,
                            ),
                            style: TextStyle(height: 2.5),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!_validateEmail(value)) {
                                return 'Please enter your college mail id';
                              }
                              return null;
                            },
                            onChanged: (value) async {
                              setState(() {
                                _isEmailValid = _validateEmail(value);
                                _isEmailUsed = false;
                              });
                              if (_isEmailValid) {
                                bool isEmailUsed =
                                await checkEmailUsed(value);
                                if (isEmailUsed) {
                                  setState(() {
                                    _isEmailUsed = true;
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFFE1E1E5),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFD9D9D9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                              isDense: true,
                            ),
                            style: TextStyle(height: 2.5),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (!isPasswordValid(value)) {
                                return 'Password must meet the following criteria:\n'
                                    '• 6-12 characters long\n'
                                    '• At least one special character\n'
                                    '• At least one number\n'
                                    '• At least one uppercase letter\n'
                                    '• At least one lowercase letter';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Confirm Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirm Password',
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFFE1E1E5),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFD9D9D9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                              isDense: true,
                            ),
                            style: TextStyle(height: 2.5),
                            validator: (value) {
                              if (value != passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Already a user? Login
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, LoginPage.routeName);
                        },
                        child: Text(
                          'Already a user? Login',
                          style: TextStyle(
                            color: Color(0xFFE1E1E5),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Sign Up Button
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            String email = emailController.text;
                            String password = passwordController.text;
                            bool isEmailUsed =
                            await checkEmailUsed(email);
                            if (isEmailUsed) {
                              setState(() {
                                _isLoading = false;
                              });
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Email Already Used'),
                                    content: Text(
                                        'The email entered is already registered.'),
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
                            } else {
                              bool isSuccess = await MongoDatabase.saveUser(
                                  email, password);
                              if (isSuccess) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Sign Up Successful'),
                                      content: Text(
                                          'You have successfully signed up.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pushReplacementNamed(
                                              context,
                                              LoginPage.routeName,
                                            );
                                          },
                                          child: Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Sign Up Error'),
                                      content: Text(
                                          'An error occurred while signing up. Please try again.'),
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
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE1E1E5),
                          foregroundColor: Color(0xFF1D0E58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1D0E58),
                          ),
                        )
                            : Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateEmail(String email) {
    return email.endsWith('@vitapstudent.ac.in');
  }

  Future<bool> checkEmailUsed(String email) async {
    return await MongoDatabase.checkEmailUsed(email);
  }
}