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
import 'package:ebrevet_card/mylogger.dart';
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
  final spacerBox = const SizedBox(
    height: 16,
  );

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
        child: ListView(
          children: [
            Column(
              children: [
                RequiredAppSettings(
                  collapsed: true,
                  onContinue: () => {},
                ),
                spacerBox,
                const EventSearchSettings(),
                spacerBox,
                OptionalAppSettings(
                  onClear: () => setState(() {}),
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

class EventSearchSettings extends StatefulWidget {
  // final void Function() onClear;

  final bool initiallyExpanded;

  const EventSearchSettings({super.key, this.initiallyExpanded = false});

  @override
  State<EventSearchSettings> createState() => _EventSearchSettingsState();
}

class _EventSearchSettingsState extends State<EventSearchSettings> {
  final spacerBox = const SizedBox(
    height: 16,
  );

  @override
  Widget build(BuildContext context) {
    var sourceSelection = context.watch<SourceSelection>();
    List<DropdownMenuItem<int>> regionList = [];
    final Key key = UniqueKey();

    // MyLogger.entry('Rebuilding region dropdown list.');

    // In some weird situations we could have a current region set
    // to be somethnig that's not in the region map.

    if (false == Region.regionMap.containsKey(AppSettings.regionID.value)) {
      MyLogger.entry('Configured for region not in map. Setting to default.');
      AppSettings.regionID.setValue(Region.defaultRegion);
      AppSettings.futureEventsSourceID.setValue(FutureEventsSourceID.defaultID);
    }

    // fromRegion and fromInternationalRegion are essentiall
    //the same "region" data source that view different subsets
    // of the same Region.regionMap
    // These are handy predicates to decide which "view" is active
    bool viewUSRegions = AppSettings.futureEventsSourceID.value ==
        FutureEventsSourceID.fromRegion;
    bool viewInternationalRegions = AppSettings.futureEventsSourceID.value ==
        FutureEventsSourceID.fromInternationalRegion;
    bool viewAllRegions = viewUSRegions || viewInternationalRegions;

    // Create the drop down list of all viewed regions
    List<int> sortedRegionIDs = Region.regionMap.keys.toList();
    sortedRegionIDs.sort((a, b) => Region.compareByStateName(a, b));
    bool isRegionSettingInList = false; // while we're at it, check this
    for (var regionID in sortedRegionIDs) {
      assert(Region.regionMap.containsKey(regionID));
      var rgn = Region(regionID: regionID);
      if (AppSettings.regionID.value == regionID) {
        isRegionSettingInList =
            true; // Good, and always include it in the dropdown
      } else {
        if (viewUSRegions && rgn.countryCode != 'US') continue;
        if (viewInternationalRegions && rgn.countryCode == 'US') {
          continue;
        }
      }

      String itemText = rgn.regionName;
      var ddmi = DropdownMenuItem(
        value: regionID,
        child: Text(itemText),
      );
      regionList.add(ddmi);
    }

    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        title: const Text('Event Info Source'),
        subtitle: const Text('From where to obtain event info'),
        initiallyExpanded: widget.initiallyExpanded,
        children: [
          RadioButtonSettingsTile(
            AppSettings.futureEventsSourceID,
            onChanged: sourceSelection.updateFromSettings,
          ),
          if (viewAllRegions)
            if (Region.regionMap.containsKey(AppSettings.regionID.value))
              DropDownSettingsTile(
                AppSettings.regionID,
                key: key,
                itemList: regionList,
                valueValid: isRegionSettingInList,
                onChanged: sourceSelection.updateFromSettings,
              )
            else
              const Text("Somehow the region selected is not in the "
                  "list of regions this app knows about. Please try refreshing the region list."),
          spacerBox,
          if (viewAllRegions)
            Column(
              children: [
                const Text(
                    "If your region is not in either the RUSA or Intl list, "
                    "try getting the latest region list from the server."),
                ElevatedButton(
                  onPressed: () async {
                    await Region.fetchRegionsFromServer();
                    setState(() {});
                  },
                  child: const Text('Get Latest Region List'),
                ),
              ],
            ),

          // if (AppSettings.futureEventsSourceID.value ==
          //     FutureEventsSourceID.fromPerm)
          //   DialogInputSettingsTile(
          //     AppSettings.permSearchLocation,
          //     onChanged: sourceSelection.updateFromSettings,
          //   ),
          // if (AppSettings.futureEventsSourceID.value ==
          //     FutureEventsSourceID.fromPerm)
          //   DialogInputSettingsTile(
          //     AppSettings.permSearchRadius,
          //     onChanged: sourceSelection.updateFromSettings,
          //   ),
          if (AppSettings.futureEventsSourceID.value ==
              FutureEventsSourceID.fromURL)
            DialogInputSettingsTile(
              AppSettings.eventInfoURL,
              onChanged: sourceSelection.updateFromSettings,
            ),
          spacerBox
        ],
      ),
    );
  }
}

class OptionalAppSettings extends StatefulWidget {
  final void Function() onClear;

  const OptionalAppSettings({
    super.key,
    required this.onClear,
  });

  @override
  State<OptionalAppSettings> createState() => _OptionalAppSettingsState();
}

class _OptionalAppSettingsState extends State<OptionalAppSettings> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        title: const Text('Preferences'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
            child: Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Column(children: [
                  SwitchSettingsTile(AppSettings.allowCheckinComment),
                  DialogInputSettingsTile(AppSettings.gpsRefreshPeriod),
                ])),
          ),
        ],
      ),
    );
  }
}

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
    var sourceSelection = context.read<SourceSelection>();
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
                  SwitchSettingsTile(AppSettings.canCheckInLate),
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
                    onPressed: () {
                      FutureEvents.clear();
                      sourceSelection.updateFromSettings();
                    },
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
