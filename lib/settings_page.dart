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

import 'package:ebrevet_card/future_events.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'day_night.dart';
import 'app_settings.dart';
import 'settings_tiles.dart';
import 'my_settings.dart';
import 'region.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });
  @override
  SettingsPageState createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage> {
  final regionList = [
    for (var k in Region.regionMap.keys)
      DropdownMenuItem(
        value: k,
        child: Text(
            "${Region.regionMap[k]!['state_code']!}: ${Region.regionMap[k]!['region_name']!}"),
      )
  ];

  @override
  Widget build(BuildContext context) {
    var dayNight = context.watch<DayNight>();
    var sourceSelection = context.watch<SourceSelection>();
    var spacerBox = const SizedBox(
      height: 16,
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
        child: ListView(
          children: [
            Column(
              children: [
                RequiredAppSettings(
                  collapsed: true,
                  onContinue: () => {},
                ),
                spacerBox,
                Material(
                  color: Colors.transparent,
                  child: ExpansionTile(
                    title: const Text('Event Info Source'),
                    subtitle: const Text('Where to download event info'),
                    children: [
                      RadioButtonSettingsTile(
                        AppSettings.futureEventsSourceID,
                        onChanged: sourceSelection.updateFromSettings,
                      ),
                      if (AppSettings.futureEventsSourceID.value ==
                          FutureEventsSourceID.fromRegion)
                        DropDownSettingsTile(
                          AppSettings.regionID,
                          itemList: regionList,
                          onChanged: sourceSelection.updateFromSettings,
                        ),
                      if (AppSettings.futureEventsSourceID.value ==
                          FutureEventsSourceID.fromURL)
                        DialogInputSettingsTile(
                          AppSettings.eventInfoURL,
                          onChanged: sourceSelection.updateFromSettings,
                        ),
                      spacerBox
                    ],
                  ),
                ),
                spacerBox,
                if (AppSettings.isMagicRusaID)
                  AdvancedSettings(
                    onClear: () => setState(() {}),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/*   ExpansionTile eventInfoDownloadSettings() {
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
    final regionList = [
      for (var k in Region.regionMap.keys)
        DropdownMenuItem(
          value: k,
          child: Text(
              "${Region.regionMap[k]!['state_code']!}: ${Region.regionMap[k]!['region_name']!}"),
        )
    ];

    switch (s) {
      case EventInfoSource.rusaRegion:
        return DropDownSettingsTile(
          AppSettings.regionID,
          itemList: regionList,
        );

      // break;

      case EventInfoSource.eventInfoURL:
        return DialogInputSettingsTile(AppSettings.eventInfoURL);
      default:
        return const Text('Unimplemented tile');
      // break;
    }
  }
}
 */
class AdvancedSettings extends StatefulWidget {
  final void Function() onClear;

  const AdvancedSettings({
    super.key,
    required this.onClear,
  });

  @override
  State<AdvancedSettings> createState() => _AdvancedSettingsState();
}

class _AdvancedSettingsState extends State<AdvancedSettings> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        title: const Text('Developer Options'),
        subtitle: const Text("Using these may disqualify your ride."),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
            child: Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Column(children: [
                  SwitchSettingsTile(AppSettings.openTimeOverride),
                  SwitchSettingsTile(AppSettings.prerideDateWindowOverride),
                  SwitchSettingsTile(AppSettings.canDeletePastEvents),
                  SwitchSettingsTile(AppSettings.controlProximityOverride),
                  DialogInputSettingsTile(AppSettings.proximityRadius),
                  const SizedBox(
                    height: 16,
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        MySetting.clear().then((_) => widget.onClear()),
                    child: const Text('Clear All Settings'),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  ElevatedButton(
                    onPressed: () => FutureEvents.clear(),
                    child: const Text('Clear Event List'),
                  ),
                ])),
          ),
        ],
      ),
    );
  }
}

class RequiredAppSettings extends StatelessWidget {
  final void Function()? onContinue;
  final bool collapsed;

  const RequiredAppSettings({
    super.key,
    this.onContinue,
    this.collapsed = true,
  });
  final spacerBox = const SizedBox(
    height: 10,
  );
  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Material(
        color: Colors.transparent,
        child: ExpansionTile(
          title: const Text('Rider Settings'),
          subtitle: const Text('Name and ID'),
          children: requiredSettingsList(),
        ),
      );
    } else {
      return ListView(
        children: [
          Text(
            'Required Settings',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            'Enter your First Name, Last Name, and Rider ID',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          // Text(
          //   'and the Region for downloading future events',
          //   style: Theme.of(context).textTheme.bodySmall,
          // ),
          spacerBox,
          ...requiredSettingsList(),
          spacerBox,
          ElevatedButton(onPressed: onContinue, child: const Text('Continue')),
        ],
      );
    }
  }

  List<Widget> requiredSettingsList() {
    return [
      DialogInputSettingsTile(AppSettings.firstName),
      DialogInputSettingsTile(AppSettings.lastName),
      DialogInputSettingsTile(AppSettings.rusaID),
    ];
  }
}
