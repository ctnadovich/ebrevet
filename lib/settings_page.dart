import 'package:ebrevet_card/future_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'rider.dart';
import 'region.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  SettingsPageState createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage> {

  // This should be called when the RUSA ID changes or for any other
  // time when we want to blow away previous rider event records.

  //  void _clear() {
  //   FutureEvents.clear();
  //   Current.clear();
  //   EventHistory.clear();
  // }

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      children: [
        ExpandableSettingsTile(
          title: 'Rider Profile',
          children: <Widget>[
            TextInputSettingsTile(
              settingKey: 'key-first-name',
              title: 'First Name',
              initialValue: '',
              validator: textFieldValidator,
            ),
            TextInputSettingsTile(
              settingKey: 'key-last-name',
              title: 'Last Name',
              initialValue: '',
              validator: textFieldValidator,
            ),
            TextInputSettingsTile(
              settingKey: 'key-rusa-id',
              title: 'RUSA ID Number',
              initialValue: '',
              validator: rusaFieldValidator,
            ),
            DropDownSettingsTile<int>(
              title: 'Events Region',
              settingKey: 'key-region',
              values: <int, String>{
                for (var k in Region.regionMap.keys)
                  k: Region.regionMap[k]!['name']!
              },
              selected: Region.defaultRegion,
              onChange: (value) =>  FutureEvents.clear(),

            ),
          ],
        ),
        ExpandableSettingsTile(
          title: 'App Options',
          children: <Widget>[
            SwitchSettingsTile(
              leading: const Icon(Icons.fast_forward),
              title: 'Pre-ride Mode',
              settingKey: 'key-preride-mode',
            ),
            SliderSettingsTile(
              settingKey: 'key-control-distance-threshold',
              title: 'Control Distance Threshold (meters)',
              defaultValue: 500,
              min: 0,
              max: 1000,
              step: 25,
              leading: const Icon(Icons.radar),
            ),
            SliderSettingsTile(
              settingKey: 'key-location_poll-period',
              title: 'Period of Location Poll (seconds)',
              defaultValue: 60,
              min: 10,
              max: 120,
              step: 10,
              leading: const Icon(Icons.access_time),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
              onPressed: () => _showAboutDialog(),
              child: Text('About this app')),
        )
      ],
    );
  }

  String? textFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter something';
    }
    return null;
  }

  String? urlFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter something';
    }
    if (false == Uri.parse(value).host.isNotEmpty) {
      return 'Invalid URL';
    } else {
      return null;
    }
  }

  String? rusaFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your RUSA ID';
    }
    if (false == Rider.isValidRusaID(value)) return 'Invalid RUSA ID';
    return null;
  }

  void _showAboutDialog() {
    showAboutDialog(
        context: context,
        applicationName: 'eBrevetCard',
        applicationIcon: FlutterLogo(),
        applicationVersion: '0.1.0',
        applicationLegalese: '(c)2023 Chris Nadovich',
        children: [
          SizedBox(
            height: 16,
          ),
          Text(
            'An electronic brevet card application for Electronic Proof of Passage in Randonneuring.',
            textAlign: TextAlign.center,
          ),
        ]);
  }
}
