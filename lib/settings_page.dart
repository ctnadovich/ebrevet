// Copyright (C) 2023 Chris Nadovich
// This file is part of eBrevet <https://github.com/ctnadovich/ebrevet>.
//
// eBrevet is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// eBrevet is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with dogtag.  If not, see <http://www.gnu.org/licenses/>.

import 'package:ebrevet_card/future_events.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
              onChange: (value) => FutureEvents.clear(),
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
        applicationIcon: Image.asset('assets/images/eBrevet-128.png',width: 64,),
        applicationVersion: '0.1.0',
        applicationLegalese:
            '(c)2023 Chris Nadovich. This free application is licensed under GPLv3.',
        children: [
          SizedBox(
            height: 16,
          ),
          Text(
            'An electronic brevet card application for Electronic Proof of Passage in Randonneuring.',
            textAlign: TextAlign.center,
          ),
          InkWell(
            onTap: () => launchUrl(Uri.parse('https://github.com/ctnadovich/ebrevet')),
            child: Text(
              'Documentation and Source Code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color.fromRGBO(0, 0, 128, 1),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline),
              
            ),
          ),
        ]);
  }
}
