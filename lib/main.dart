import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'MyApp.dart';

Future main() async {
  await Settings.init(cacheProvider: SharePreferenceCache());
  runApp(MyApp());
}
