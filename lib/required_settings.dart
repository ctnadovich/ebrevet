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

import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'settings_tiles.dart';

class RequiredAppSettings extends StatelessWidget {
  final bool isExpandable;
  const RequiredAppSettings({
    super.key,
    this.isExpandable = false,
  });
//   @override
//   State<RequiredAppSettings> createState() => _RequiredAppSettingsState();
// }

// class _RequiredAppSettingsState extends State<RequiredAppSettings> {
  final spacerBox = const SizedBox(
    height: 10,
  );
  @override
  Widget build(BuildContext context) {
    if (isExpandable) {
      return ExpansionTile(
        title: const Text('Rider Settings'),
        subtitle: const Text('Name and ID'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
            child: Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Column(
                  children: requiredSettingsList(),
                )),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Text(
            'Enter First Name, Last Name, and Rider ID',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          spacerBox,
          ...requiredSettingsList(),
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
