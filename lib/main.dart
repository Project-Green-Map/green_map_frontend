import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:provider/provider.dart';
import 'MyApp.dart';

import 'services/settings_prefs.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsPrefs.onStart();
  await Settings.init(cacheProvider: SharePreferenceCache());
  runApp(MyApp());
}
