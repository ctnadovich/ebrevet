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
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:ebrevet_card/event_history.dart';
import 'package:ebrevet_card/app_settings.dart';
import 'package:provider/provider.dart';

import 'snackbarglobal.dart';
import 'future_events_page.dart';
import 'future_events.dart';
import 'region.dart';
import 'day_night.dart';
import 'mylogger.dart';

void main() {
  initSettings().then((_) {
    MyLogger.entry("** runApp(MyApp)");
    runApp(const MyApp());
  });
}

Future<void> initSettings() async {
  MyLogger.entry('Init settings start...');
  await Settings.init(
    cacheProvider: SharePreferenceCache(),
  );
  await AppSettings.initializePackageInfo();
  await FutureEvents.refreshEventsFromDisk(Region.fromSettings());
  // .then((_) =>
  await EventHistory.load();
  MyLogger.entry('...Init settings end');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // @override
  // Widget build(BuildContext context) {
  //   return AdaptiveTheme(
  //     light: ThemeData(
  //       brightness: Brightness.light,
  //       // primarySwatch: Colors.red,
  //       // accentColor: Colors.amber,
  //     ),
  //     dark: ThemeData(
  //       brightness: Brightness.dark,
  //       // primarySwatch: Colors.red,
  //       // accentColor: Colors.amber,
  //     ),
  //     initial: AdaptiveThemeMode.light,
  //     builder: (theme, darkTheme) => MaterialApp(
  //       scaffoldMessengerKey: SnackbarGlobal.key,
  //       title: 'eBrevet Card',
  //       debugShowCheckedModeBanner: false,
  //       theme: theme,
  //       darkTheme: darkTheme,
  //       home: HomePage(),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DayNight>(
        create: (_) => DayNight(),
        child: Consumer<DayNight>(builder: (context, dayNight, child) {
          return MaterialApp(
            scaffoldMessengerKey: SnackbarGlobal.key,
            title: 'eBrevet Card',
            debugShowCheckedModeBanner: false,
            theme: dayNight.dayTheme,
            darkTheme: dayNight.nightTheme,
            themeMode: dayNight.mode,
            home: const EventsPage(),
//            home: const HomePage(),
          );
        }));
  }
}
