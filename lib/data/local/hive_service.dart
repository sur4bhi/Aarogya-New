import 'package:hive/hive.dart';

class HiveService {
  static Future<void> init() async {
    // Initialize Hive in your app's main() or startup flow
  }

  static Future<Box> openBox(String name) async {
    return Hive.openBox(name);
  }
}
