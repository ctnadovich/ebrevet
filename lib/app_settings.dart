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
import 'package:package_info_plus/package_info_plus.dart';

import 'rider.dart';
import 'region.dart';
import 'region_data.dart';

class AppSettings {
  // static bool get isPrerideMode =>
  //     Settings.getValue<bool>('key-preride-mode', defaultValue: false)!;


static String? appName;
static String? packageName;
static String? version;
static String? buildNumber;

static Future <void> initializePackageInfo() async {
PackageInfo packageInfo = await PackageInfo.fromPlatform();

 appName = packageInfo.appName;
 packageName = packageInfo.packageName;
 version = packageInfo.version;
 buildNumber = packageInfo.buildNumber;

}

  static const int infiniteDistance=9999999;
  static const int startableTimeWindowMinutes = 60;
  static const int prerideTimeWindowDays = 15;

  static double get proximityRadius {
    var d =Settings.getValue<int>('key-control-proximity-thresh',
       defaultValue: 500)!;
    return d.toDouble();
  }
  static bool get openTimeOverride{
    return Settings.getValue('key-open-time-override', defaultValue: false)!;
  }

  static bool get prerideDateWindowOverride{
    return Settings.getValue('key-preride-date-window-override', defaultValue: false)!;
  }

  static double get locationPollPeriod {
    var d = Settings.getValue<double>('key-location-poll-period',
        defaultValue: 500)!;
    return d;
  }

  static int get regionID => Settings.getValue<int>('key-region',
      defaultValue: RegionData.defaultRegion)!;
}

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
            // TextInputSettingsTile(
            //   settingKey: 'key-first-name',
            //   title: 'First Name',
            //   initialValue: '',
            //   validator: textFieldValidator,
            // ),
            // TextInputSettingsTile(
            //   settingKey: 'key-last-name',
            //   title: 'Last Name',
            //   initialValue: '',
            //   validator: textFieldValidator,
            // ),
            TextInputSettingsTile(
              settingKey: 'key-rusa-id',
              title: 'RUSA ID Number',
              initialValue: '',
              validator: rusaFieldValidator,
            ),
            DropDownSettingsTile<int>(
              title: 'Events Club',
              settingKey: 'key-region',
              values: <int, String>{
                for (var k in Region.regionMap.keys)
                  k: Region.regionMap[k]!['clubName']!
              },
              selected: Region.defaultRegion,
              onChange: (value) {FutureEvents.clear();},
            ),
          ],
        ),
        ExpandableSettingsTile(
          title: 'Advanced Options',
          children: <Widget>[
            RadioSettingsTile<int>(
              leading: const Icon(Icons.social_distance),
              title: 'Control Proximity Radius',
              subtitle: 'Distance from control that allows check-in',
              settingKey: 'key-control-proximity-thresh',
              values: <int, String>{
                100: '100 m',
                500: '500 m',
                2500: '2.5 km',
                12500: '12.5 km',
                AppSettings.infiniteDistance: 'Infinite',
              },
              selected: 500,
            ),
            SwitchSettingsTile(
              title: "Open Time Override", 
              settingKey: "key-open-time-override",
              subtitle: "Ignore control open/close time.",
                            leading: const Icon(Icons.free_cancellation),
              ),
           SwitchSettingsTile(
              title: "Preride Date Window Override", 
              settingKey: "key-preride-date-window-override",
              subtitle: "Preride any time.",
                            leading: const Icon(Icons.free_cancellation),
              ),
            SliderSettingsTile(
              settingKey: 'key-location-poll-period',
              title: 'Period of Location Poll (seconds)',
              subtitle: "How often the GPS location is updated.",
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
        applicationIcon: Image.asset(
          'assets/images/eBrevet-128.png',
          width: 64,
        ),
        applicationVersion:
            "v${AppSettings.version ?? '?'}", 
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
            onTap: () =>
                launchUrl(Uri.parse('https://github.com/ctnadovich/ebrevet')),
            child: Text(
              'Documentation and Source Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color.fromRGBO(0, 0, 128, 1),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline),
            ),
          ),
        ]);
  }
}
