import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'MyApp.dart';
import './models/settings_notifiers.dart';

void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => SingleSetting(),
        child: MyApp(),
      ),
    );
