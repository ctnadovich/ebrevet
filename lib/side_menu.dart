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

import 'package:ebrevet_card/past_events_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_settings.dart';
import 'settings_page.dart';
import 'log_page.dart';

class SideMenuDrawer extends StatelessWidget {
  final Function? onClose;
  const SideMenuDrawer({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var menuTitleStyle = textTheme.titleLarge;
    var menuItemStyle = textTheme.titleMedium;
    var headerColor = Theme.of(context).colorScheme.primaryContainer;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: headerColor,
            ),
            child: Text('eBrevet Main Menu', style: menuTitleStyle),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(
              'Settings',
              style: menuItemStyle,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ))
                  .then((value) => onClose?.call());
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(
              'Past Events',
              style: menuItemStyle,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const PastEventsPage(),
              ));
              //.then((value) => onClose?.call());
            },
          ),
          // if (AppSettings.isMagicRusaID)  // Everyone can see log
          ListTile(
            leading: const Icon(Icons.newspaper),
            title: Text(
              'Activity Log',
              style: menuItemStyle,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const LogPage(),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(
              'About eBrevet',
              style: menuItemStyle,
            ),
            onTap: () {
              Navigator.pop(context);
              aboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void aboutDialog(BuildContext context) {
    showAboutDialog(
        context: context,
        applicationName: 'eBrevet',
        applicationIcon: Image.asset(
          'assets/images/eBrevet-128.png',
          width: 64,
        ),
        applicationVersion:
            "v${AppSettings.version ?? '?'}(${AppSettings.buildNumber})",
        applicationLegalese:
            '(c)2023 Chris Nadovich. This is free software licensed under GPLv3.',
        children: [
          const SizedBox(
            height: 16,
          ),
          const Text(
            'An electronic brevet card application for Electronic Proof of Passage in Randonneuring.',
            textAlign: TextAlign.center,
          ),
          InkWell(
            onTap: () =>
                launchUrl(Uri.parse('https://github.com/ctnadovich/ebrevet')),
            child: const Text(
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
