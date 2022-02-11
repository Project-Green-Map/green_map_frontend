import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIManager {
  APIManager() {
    dotenv.load(fileName: ".env");
  }

  String getKey() {
    String? key = dotenv.env['API_KEY'];
    return (key == null) ? '' : key;
  }
}
