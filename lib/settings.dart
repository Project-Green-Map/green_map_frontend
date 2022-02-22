import 'package:flutter/material.dart';
import 'package:map/models/settings_notifiers.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  Settings({Key? key}) : super(key: key);
  static const List<String> possibleDistanceUnit = ['km', 'miles'];

  @override
  Widget build(BuildContext context) {
    var singleSetting = Provider.of<SingleSetting>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: SettingsList(
          sections: [
            SettingsSection(
              title: Text('Common'),
              tiles: <SettingsTile>[
                SettingsTile.navigation(
                  leading: Icon(Icons.language),
                  title: Text('Language'),
                  value: Text('English'),
                ),
                SettingsTile.navigation(
                    leading: Icon(Icons.format_paint),
                    title: Text('Distance units'),
                    value: Text(singleSetting.distanceUnit),
                    onPressed: (context) => {
                          showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                  title: Text('Dialog Title'),
                                  content: SingleChildScrollView(
                                    child: Container(
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: possibleDistanceUnit
                                            .map((e) => RadioListTile(
                                                  title: Text(e),
                                                  value: e,
                                                  groupValue: singleSetting
                                                      .distanceUnit,
                                                  selected: singleSetting
                                                          .distanceUnit ==
                                                      e,
                                                  onChanged: (value) {
                                                    if (value as String !=
                                                        singleSetting
                                                            .distanceUnit) {
                                                      singleSetting
                                                          .updateDistanceUnit(
                                                              value);
                                                      Navigator.of(context)
                                                          .pop();
                                                    }
                                                  },
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  )))
                        }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
