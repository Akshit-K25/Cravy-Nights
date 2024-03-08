import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:classico/food_item.dart';

class NightCanteenService {
  final String baseUrl;

  NightCanteenService({required this.baseUrl});

  Future<void> submitOrder(List<FoodItem> items, int quantity, int token) async {
    final order = {
      'items': items.map((item) => {'name': item.name, 'price': item.price}).toList(),
      'quantity': quantity,
      'token': token,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/submitOrder'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(order),
    );

    if (response.statusCode == 201) {
      print('Order submitted successfully');
    } else {
      print('Failed to submit order. Status code: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/getOrders'));

    if (response.statusCode == 200) {
      final List<dynamic> ordersJson = jsonDecode(response.body);
      return ordersJson.cast<Map<String, dynamic>>();
    } else {
      print('Failed to fetch orders. Status code: ${response.statusCode}');
      return [];
    }
  }
}
