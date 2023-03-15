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

import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:ebrevet_card/event_history.dart';
import 'package:ebrevet_card/app_settings.dart';
import 'package:ebrevet_card/outcome.dart';
import 'package:provider/provider.dart';

import 'snackbarglobal.dart';
import 'future_events_page.dart';
import 'past_events_page.dart';
import 'ride_page.dart';
import 'future_events.dart';
import 'region.dart';
import 'current.dart';
import 'day_night.dart';
import 'mylogger.dart';

void main() {
  initSettings().then((_) {
    MyLogger.logInfo("** runApp(MyApp)");
    runApp(const MyApp());
  });
}

Future<void> initSettings() async {
  MyLogger.logInfo('Init settings start...');
  await Settings.init(
    cacheProvider: SharePreferenceCache(),
  );
  await AppSettings.initializePackageInfo();
  await FutureEvents.refreshEventsFromDisk(Region.fromSettings());
  // .then((_) =>
  await EventHistory.load();
  MyLogger.logInfo('...Init settings end');
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
            home: const HomePage(),
          );
        }));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController controller;

  // bool rusaError = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var dayNight = context.watch<DayNight>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'eBrevet Card',
        ),
        actions: [
          IconButton(
              icon: dayNight.icon,
              onPressed: () {
                dayNight.toggleMode();
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ))
            .then((value) => setState(
                  () {},
                )),
        child: const Icon(Icons.settings),
      ),
      body: (AppSettings.isRusaIDSet)
          ? mainMenu(context)
          : requiredSettings(), //  rusaIDField(),
    );
  }

  Column requiredSettings() {
    return Column(children: [
      const Text('Enter your RUSA number and select a Club/Region:'),
      const SizedBox(
        height: 10,
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          decoration: const InputDecoration(hintText: 'Enter your RUSA ID'),
          autofocus: true,
          controller: controller,
          validator: (value) => AppSettings.rusaFieldValidator(value),
          onChanged: (_) => submitRusaID(),
        ),
      ),
      DropDownSettingsTile<int>(
          title: 'Events Club',
          settingKey: 'key-region',
          selected: Region.defaultRegion,
          values: <int, String>{
            for (var k in Region.regionMap.keys)
              k: Region.regionMap[k]!['clubName']!
          }),
      const SizedBox(
        height: 15,
      ),
      ElevatedButton(onPressed: () => setState(() {}), child: const Text('Continue')),
    ]);
  }

  void submitRusaID() {
    var rusaIDString = controller.text.trim();
    if (AppSettings.isValidRusaID(rusaIDString)) {
      AppSettings.setRusaID(rusaIDString);
      // controller.clear();
    }
  }

  Container mainMenu(BuildContext context) {
    var style = const TextStyle(
      fontSize: 20,
    );

    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 4),
              ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                        builder: (context) =>
                            const EventsPage(), // will implicitly ride event just activated
                      ))
                      .then((value) => setState(
                            () {},
                          )),
                  child: Text(
                    'Future Events',
                    style: style,
                  )),
              const Spacer(flex: 1),
              ElevatedButton(
                  onPressed: (Current.isActivated ||
                          Current.outcomes?.overallOutcome ==
                              OverallOutcome.active)
                      ? () => Navigator.of(context)
                          .push(MaterialPageRoute(
                            builder: (context) =>
                                const RidePage(), // will implicitly ride event just activated
                          ))
                          .then((value) => setState(
                                () {},
                              ))
                      : null,
                  child: Text(
                    'Current Event',
                    style: style,
                  )),
              const Spacer(flex: 1),
              ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                        builder: (context) =>
                            const PastEventsPage(), // will implicitly ride event just activated
                      ))
                      .then((value) => setState(
                            () {},
                          )),
                  child: Text(
                    'Past Events',
                    style: style,
                  )),
              const Spacer(flex: 1),
              // ElevatedButton(
              //     onPressed: () => Navigator.of(context)
              //         .push(MaterialPageRoute(
              //           builder: (context) =>
              //               SettingsPage(), // will implicitly ride event just activated
              //         ))
              //         .then((value) => setState(
              //               () {},
              //             )),
              //     child: Text(
              //       'Settings',
              //       style: style,
              //     )),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }


}
