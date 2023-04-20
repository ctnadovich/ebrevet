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

import 'package:ebrevet_card/required_settings.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:provider/provider.dart';

import 'day_night.dart';
import 'app_settings.dart';
import 'settings_tiles.dart';
import 'my_settings.dart';

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
    var spacerBox = const SizedBox(
      height: 24,
    );
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
              const RequiredAppSettings(
                isExpandable: true,
              ),
              spacerBox,
              // eventInfoDownloadSettings(),
              // spacerBox,
              // ColorPickerSettingsTile(
              //   title: 'Theme Color',
              //   settingKey: 'key-theme-color',
              //   onChange: (p0) {
              //     dayNight.color = p0;
              //   },
              // ),
              spacerBox,
              AppSettings.isMagicRusaID
                  ? advancedSettings()
                  : const SizedBox.shrink(),
              spacerBox,
              ElevatedButton(
                onPressed: () =>
                    MySetting.clear().then((_) => setState(() => {})),
                child: const Text('Clear All Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ExpansionTile eventInfoDownloadSettings() {
    var spacerBox = const SizedBox(
      height: 8,
    );
    return ExpansionTile(
        title: const Text('Event Info Download'),
        subtitle: const Text('Where to get event information'),
        children: <Widget>[
          RadioSettingsTile(AppSettings.eventInfoSource),
          infoSourceParameterEntry(
              AppSettings.eventInfoSource.value as EventInfoSource),
          spacerBox,
          spacerBox,
          spacerBox,
        ]);
  }

  Widget infoSourceParameterEntry(EventInfoSource s) {
    switch (s) {
      case EventInfoSource.rusaRegion:
        return DropDownSettingsTile(AppSettings.regionID);

      // break;

      case EventInfoSource.eventInfoURL:
        return DialogInputSettingsTile(AppSettings.eventInfoURL);
      default:
        return const Text('Unimplemented tile');
      // break;
    }
  }

  ExpansionTile advancedSettings() {
    // var dayNight = context.watch<DayNight>();

    return ExpansionTile(
      title: const Text('Advanced Options'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
          child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Column(
                children: advancedSettingsList,
              )),
        ),
      ],
    );
  }

  List<Widget> get advancedSettingsList {
    return <Widget>[
      SwitchSettingsTile(AppSettings.openTimeOverride),
      SwitchSettingsTile(AppSettings.prerideDateWindowOverride),
      SwitchSettingsTile(AppSettings.canDeletePastEvents),
      SwitchSettingsTile(AppSettings.controlProximityOverride),
      DialogInputSettingsTile(AppSettings.proximityRadius),
    ];
  }

  String? textFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter something';
    }
    return null;
  }
}
