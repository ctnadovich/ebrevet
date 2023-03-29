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
// along with eBrevet.  If not, see <http://www.gnu.org/licenses/>.

// import 'package:ebrevet_card/day_night.dart';
import 'package:ebrevet_card/future_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'region.dart';
import 'region_data.dart';
import 'day_night.dart';

class AppSettings {
  // static bool get isPrerideMode =>
  //     Settings.getValue<bool>('key-preride-mode', defaultValue: false)!;

  static String? appName;
  static String? packageName;
  static String? version;
  static String? buildNumber;

  static Future<void> initializePackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
  }

  static const int infiniteDistance = 9999999;
  static const int startableTimeWindowMinutes = 60;
  static const int prerideTimeWindowDays = 15;
  static const int httpGetTimeoutSeconds = 15;
  static const int timeRefreshPeriod = 60;
  static const int gpsRefreshPeriod = 20;
  static const int maxRUSAID = 99999;

  static Color get themeColor {
    var colorString =
        Settings.getValue('key-theme-color', defaultValue: '#0000FF00')!;
    var colorColor = hexToColor(colorString);
    return colorColor;
  }

  static Color hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  // static const magicStartCode = "XYZZY";

  static String get magicStartCode {
    return Settings.getValue<String>('key-magic-start-code',
        defaultValue: 'XYZZY')!;
  }

  static double get proximityRadius {
    var d = Settings.getValue<int>('key-control-proximity-thresh',
        defaultValue: 500)!;
    return d.toDouble();
  }

  static bool get openTimeOverride {
    return Settings.getValue('key-open-time-override', defaultValue: false)!;
  }

  static bool get prerideDateWindowOverride {
    return Settings.getValue('key-preride-date-window-override',
        defaultValue: false)!;
  }

  // static double get locationPollPeriod {
  //   var d = Settings.getValue<double>('key-location-poll-period',
  //       defaultValue: 500)!;
  //   return d;
  // }

  static int get regionID => Settings.getValue<int>('key-region',
      defaultValue: RegionData.defaultRegion)!;

  static String get rusaID =>
      Settings.getValue<String>('key-rusa-id', defaultValue: '')!;

  static bool get isRusaIDSet => rusaID.isNotEmpty;

  static setRusaID(String r) async => await Settings.setValue('key-rusa-id', r);

  static String? urlFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter something';
    }
    if (false == Uri.parse(value).host.isNotEmpty) {
      return 'Invalid URL';
    } else {
      return null;
    }
  }

  static String? rusaFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your RUSA ID';
    }
    if (false == isValidRusaID(value)) return 'Invalid RUSA ID';
    return null;
  }

  static bool isValidRusaID(String? value) {
    if (value == null) return false;
    final rusaid = num.tryParse(value);
    if (rusaid == null || rusaid is! int || rusaid < 1 || rusaid > maxRUSAID) {
      return false;
    }
    return true;
  }
}

// SETTINGS PAGE

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  SettingsPageState createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    var dayNight = context.watch<DayNight>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          //style: TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
              icon: dayNight.icon,
              onPressed: () {
                dayNight.toggleMode();
              })
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Center(
          child: ListView(
            children: [
              TextInputSettingsTile(
                settingKey: 'key-rusa-id',
                title: 'RUSA ID Number',
                initialValue: '',
                validator: AppSettings.rusaFieldValidator,
              ),
              DropDownSettingsTile<int>(
                title: 'Events Club',
                settingKey: 'key-region',
                values: <int, String>{
                  for (var k in Region.regionMap.keys)
                    k: Region.regionMap[k]!['clubName']!
                },
                selected: Region.defaultRegion,
                onChange: (value) {
                  FutureEvents.clear();
                },
              ),
              //   ],
              // ),
              const SizedBox(
                height: 25,
              ),
              AppSettings.rusaID == AppSettings.maxRUSAID.toString()
                  ? advancedSettings()
                  : const SizedBox.shrink(),
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: ElevatedButton(
              //       onPressed: () => _showAboutDialog(),
              //       child: const Text('About this app')),
              // )
            ],
          ),
        ),
      ),
    );
  }

  ExpandableSettingsTile advancedSettings() {
    var dayNight = context.watch<DayNight>();

    return ExpandableSettingsTile(
      title: 'Advanced Options',
      children: <Widget>[
        ColorPickerSettingsTile(
          title: 'Theme Color',
          settingKey: 'key-theme-color',
          onChange: (p0) {
            dayNight.color = p0;
          },
        ),
        TextInputSettingsTile(
          settingKey: 'key-magic-start_code',
          title: 'Magic Start Code',
          // subtitle: 'Cheat code for starting any event',
          initialValue: 'XYZZY',
          validator: textFieldValidator,
        ),
        RadioSettingsTile<int>(
          leading: const Icon(Icons.social_distance),
          title: 'Control Proximity Radius',
          subtitle: 'Distance from control that allows check-in',
          settingKey: 'key-control-proximity-thresh',
          values: const <int, String>{
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
        // SliderSettingsTile(
        //   settingKey: 'key-location-poll-period',
        //   title: 'Period of Location Poll (seconds)',
        //   subtitle: "How often the GPS location is updated.",
        //   defaultValue: 60,
        //   min: 10,
        //   max: 120,
        //   step: 10,
        //   leading: const Icon(Icons.access_time),
        // ),
      ],
    );
  }

  String? textFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter something';
    }
    return null;
  }

  }
