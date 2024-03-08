import 'package:flutter/material.dart';
import 'mongodb.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isLoading = false;
  double _size = 20.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isLoading = true;
      });
    });
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await MongoDatabase.connect();

    Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0C95F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Duration(seconds: 2), // Animation duration
              curve: Curves.easeInOut, // Animation curve
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/App_Icon.jpg'),
                  fit: BoxFit.cover,
                ),
                borderRadius: _size == 20.0 ? BorderRadius.circular(10) : BorderRadius.circular(20),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Night Canteen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            if (isLoading)
              SizedBox(
                height: 35,
                width: 35,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startZoomAnimation();
  }

  void _startZoomAnimation() {
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _size = 100.0;
      });
    });
  }
}
