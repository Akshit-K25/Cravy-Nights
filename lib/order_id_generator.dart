import 'dart:math';

class OrderIdGenerator {
  static final _random = Random();
  static int _sequentialNumber = 0;

  static String generateOrderId() {
    String randomLetter = String.fromCharCode(_random.nextInt(26) + 'A'.codeUnitAt(0));
    _sequentialNumber++;
    return '$randomLetter$_sequentialNumber';
  }
}