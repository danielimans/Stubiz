import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class LocalStorage {
  static const _productKey = 'products';
  static const _loginKey = 'loggedIn';

  // PRODUCTS
  static Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = products.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_productKey, jsonList);
  }

  static Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_productKey) ?? [];
    return list.map((e) => Product.fromJson(jsonDecode(e))).toList();
  }

  // LOGIN STATE
  static Future<void> saveLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginKey, value);
  }

  static Future<bool> loadLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loginKey) ?? false;
  }

  // NOTE:
  // Exchange is now stored in Firestore (exchange_posts).
  // Local cache for exchanges is intentionally removed.
}
