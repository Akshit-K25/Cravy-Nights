import 'package:mongo_dart/mongo_dart.dart';
import 'dart:io';
import 'dart:async' show Timer;

const MONGO_URL =
    "PLACE MONNGOURL HERE!";

class MongoDatabase {
  static void Function(Order)? _retryCallback;

  static Map<String, int> lockedQuantities = {};
  static Map<String, DateTime> _lockTimestamps = {};
  static const Duration lockTimeoutDuration = Duration(seconds: 45);

  static Future<List<Map<String, dynamic>>> getItemsFromMongoDB() async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('feed');

      var items = await collection.find().toList();

      await db.close();
      print('Items fetched successfully');
      return items;
    } catch (e) {
      print('Error fetching items: $e');
      if (e is SocketException && _retryCallback != null) {
        _retryCallback!(Order(quantities: {},
            totalAmount: 0,
            orderDate: DateTime.now(),
            token: '',
            email: ''));
      }
      return [];
    }
  }

  static Future<int> getItemStock(String itemName) async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('feed');

      var item = await collection.findOne({'itemName': itemName});
      var stock = item != null ? item['itemStock'] as int? ?? 0 : 0;

      await db.close();
      return stock;
    } catch (e) {
      print('Error fetching item stock: $e');
      return 0;
    }
  }

  static Future<void> connect() async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      print('Connected to MongoDB');
    } catch (e) {
      print('Error connecting to MongoDB: $e');
    }
  }

  static Future<bool> saveUser(String email, String password) async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('users');

      await collection.insert({
        'email': email,
        'password': password,
      });

      await db.close();
      print('User saved successfully');
      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  static Future<bool> validateUser(String email, String password) async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('users');

      var user = await collection.findOne({
        'email': email,
        'password': password,
      });

      await db.close();
      return user != null;
    } catch (e) {
      print('Error validating user: $e');
      return false;
    }
  }

  static Future<bool> checkEmailUsed(String email) async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('users');

      var user = await collection.findOne({
        'email': email,
      });

      await db.close();
      return user != null;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  static Future<bool> saveOrder(Order order) async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();

      var collection = db.collection('orders');
      int orderNumber = await getNextOrderNumber();

      await collection.insert({
        'orderNumber': orderNumber,
        'email': order.email,
        'quantities': order.quantities,
        'totalAmount': order.totalAmount,
        'orderDate': order.orderDate,
        'token': order.token,
        'status': false,
      });

      var itemsCollection = db.collection('feed');
      for (var entry in order.quantities.entries) {
        var itemName = entry.key;
        var quantityOrdered = entry.value;

        var item = await itemsCollection.findOne({'itemName': itemName});
        if (item != null) {
          var currentStock = item['itemStock'] as int? ?? 0;
          var newStock = currentStock - quantityOrdered;

          await itemsCollection.update(
            {'itemName': itemName},
            {'\$set': {'itemStock': newStock}},
          );
        }
      }

      await db.close();
      return true;
    } catch (e) {
      print('Error saving order: $e');
      return false;
    }
  }

  static void setRetryCallback(void Function(Order) retryCallback) {
    _retryCallback = retryCallback;
  }

  static Future<List<Map<String, dynamic>>> getOrdersFromMongoDB() async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('orders');

      var orders = await collection.find().toList();

      await db.close();
      print('Orders fetched successfully');
      return orders;
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  static Future<int> getNextOrderNumber() async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('orders');

      var lastOrder = await collection
          .find(where.sortBy('orderNumber', descending: true))
          .first;

      print('Last order: $lastOrder');

      if (lastOrder == null) {
        return 1;
      }

      int lastOrderNumber = lastOrder['orderNumber'] as int;
      return lastOrderNumber + 1;
    } catch (e) {
      print('Error fetching next order number: $e');
      return 0;
    }
  }

  static Future<Map<String, int>> getStock() async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('feed');

      var items = await collection.find().toList();
      await db.close();

      var stockMap = <String, int>{};
      for (var item in items) {
        stockMap[item['itemName']] = item['itemStock'];
      }

      return stockMap;
    } catch (e) {
      print('Error fetching stock: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> fetchOrders(String email) async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('orders');

      var orders = await collection.find({'email': email}).toList();

      await db.close();
      print('Orders fetched successfully');
      return orders;
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  static Future<void> initializeLock(Db db) async {
    var collection = db.collection('orders');
    var lockDocument = await collection.findOne(
        {'reserve': {'\$exists': true}});

    if (lockDocument == null) {
      await collection.insert({'reserve': false});
    }
  }

  static Future<bool> acquireLock(Db db) async {
    var collection = db.collection('orders');
    final result = await collection.findAndModify(
      query: {'reserve': false},
      update: {'reserve': true},
    );

    return result != null;
  }

  static Future<void> releaseLock(Db db) async {
    var collection = db.collection('orders');
    await collection.update({'reserve': true}, {'reserve': false});
  }

  static Future<bool> lockStock(String itemName, int quantity) async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('feed');

      var item = await collection.findOne(where.eq('itemName', itemName));
      if (item != null) {
        var currentStock = item['itemStock'];
        var lockedQuantity = item['lockedQuantity'] ?? 0;
        if (currentStock != null && currentStock is int) {
          if (currentStock >= quantity + lockedQuantity) {
            await collection.update(
              where.eq('itemName', itemName),
              modify.set('locked', true).set(
                  'lockedQuantity', lockedQuantity + quantity),
            );

            _lockTimestamps[itemName] = DateTime.now();
            // Update lockedQuantities map
            lockedQuantities[itemName] =
                (lockedQuantities[itemName] ?? 0) + quantity;

            Timer(lockTimeoutDuration, () {
              unlockStock(itemName, quantity);
            });

            await db.close();
            return true;
          }
        } else {
          print('Error locking stock: Item stock is not an integer or is null');
        }
      }
      await db.close();
      return false;
    } catch (e) {
      print('Error locking stock: $e');
      return false;
    }
  }

  static Future<void> unlockStock(String itemName, int quantity) async {
    try {
      var db = await Db.create(MONGO_URL);
      await db.open();
      var collection = db.collection('feed');

      await collection.update(
        where.eq('itemName', itemName),
        modify.inc('lockedQuantity', -quantity),
      );

      var item = await collection.findOne(where.eq('itemName', itemName));
      if (item != null && (item['lockedQuantity'] ?? 0) == 0) {
        await collection.update(
          where.eq('itemName', itemName),
          modify.set('locked', false),
        );
      }
    } catch (e) {
      print("Error unlocking stock: $e");
      throw e;
    }
  }
}

class Order {
  final Map<String, int> quantities;
  final double totalAmount;
  final DateTime orderDate;
  final String token;
  final String email;

  Order({
    required this.quantities,
    required this.totalAmount,
    required this.orderDate,
    required this.token,
    required this.email,
  });
}
