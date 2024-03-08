import 'package:mongo_dart/mongo_dart.dart';

class DatabaseService {
  late Db _db;

  Future<void> connectToDb() async {
    _db = Db('mongodb://localhost:27017');
    await _db.open();
    print('Connected to MongoDB');
  }

  Future<void> registerUser(String username, String email, String password) async {
    var usersCollection = _db.collection('users');
    await usersCollection.insert({
      'username': username,
      'email': email,
      'password': password,
    });
    print('User registered successfully');
  }

  Future<bool> loginUser(String username, String password) async {
    var usersCollection = _db.collection('users');
    var user = await usersCollection.findOne({'username': username, 'password': password});
    if (user != null) {
      print('User logged in successfully');
      return true;
    } else {
      print('Invalid credentials');
      return false;
    }
  }
}
