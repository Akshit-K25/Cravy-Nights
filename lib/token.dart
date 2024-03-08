import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class TokenPage extends StatelessWidget {
  final String token;

  TokenPage({required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Token Number:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),
            Text(
              token,
              style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Text(
              'You can go approx. after 20 mins to check your order',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}