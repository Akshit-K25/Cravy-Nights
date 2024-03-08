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
      backgroundColor: Colors.green,
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        errorText: !_isEmailValid
                            ? 'Please enter your college mail id'
                            : _isEmailUsed
                            ? 'Email is already used'
                            : null,
                      ),
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
                          bool isEmailUsed = await checkEmailUsed(value);
                          if (isEmailUsed) {
                            setState(() {
                              _isEmailUsed = true;
                            });
                          }
                        }
                      },
                    ),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                      ),
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
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                      ),
                      validator: (value) {
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, LoginPage.routeName);
                      },
                      child: Text('Already a user? Login'),
                    ),
                    SizedBox(height: 20),
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
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      )
                          : Text('Sign Up'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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