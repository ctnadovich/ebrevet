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

import 'package:ebrevet_card/event_history.dart';
import 'package:ebrevet_card/app_settings.dart';
import 'package:provider/provider.dart';

import 'package:upgrader/upgrader.dart';

import 'snackbarglobal.dart';
import 'scheduled_events.dart';
import 'day_night.dart';
import 'mylogger.dart';
import 'control_state.dart';
import 'my_settings.dart';
import 'event_list_page.dart';
import 'region.dart';

void main() {
  initSettings().then((_) {
    MyLogger.entry("** runApp(MyApp)");
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => DayNight()),
          ChangeNotifierProvider(create: (context) => ControlState()),
          ChangeNotifierProvider(create: (context) => SourceSelection()),
        ],
        child: const MyApp(),
      ),
    );
  });
}

Future<void> initSettings() async {
  WidgetsFlutterBinding.ensureInitialized();
  MyLogger.entry('Init settings start...');

  FlutterError.onError = (FlutterErrorDetails errorDetails) {
    MyLogger.entry("FLT: ${errorDetails.exception.toString()}",
        severity: Severity.error);
  };

  await MySetting.initSharedPreferences();
  await AppSettings.initializePackageInfo();
  // await AppSettings.initializeMySettings();
  await Region.fetchRegionsFromDisk(
      create: true); // will create from compiled static if missing

  // There's really no reason to do this every time the app starts
  // up. If people can't find the desired region, all they need
  // do is press the Refresh Regions button. Now that the regions
  // are persistent with a disk file, there should be no reason
  // to do this live update. Region additions are rare.
  //
  // But if we ever change our minds on this point, uncomment below

  // await Region.fetchRegionsFromServer(
  //     quiet: true); // will update disk if successful

  await ScheduledEvents.refreshEventsFromDisk();
  await EventHistory.load();

  MyLogger.entry('...Init settings end');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<DayNight>(builder: (context, dayNight, child) {
      return MaterialApp(
//        scaffoldMessengerKey: OldSnackbarGlobal.key,  // to be deleted
        navigatorKey: FlushbarGlobal.navigatorKey,
        title: 'eBrevet Card',
        debugShowCheckedModeBanner: false,
        theme: dayNight.dayTheme,
        darkTheme: dayNight.nightTheme,
        themeMode: dayNight.mode,
        home: UpgradeAlert(child: const ScheduledEventsPage()),
      );
    });
  }
}
