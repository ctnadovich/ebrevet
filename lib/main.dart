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

import 'package:ebrevet_card/event_history.dart';
import 'package:ebrevet_card/app_settings.dart';
import 'package:ebrevet_card/outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'snackbarglobal.dart';
import 'future_events_page.dart';
import 'past_events_page.dart';
import 'ride_page.dart';
import 'future_events.dart';
import 'region.dart';
import 'current.dart';

void main() {
  initSettings().then((_) {
    print("** runApp(MyApp)");
    runApp(MyApp());
  });
}

Future<void> initSettings() async {
  await Settings.init(
    cacheProvider: SharePreferenceCache(),
  );
  await AppSettings.initializePackageInfo();
  await FutureEvents.refreshEventsFromDisk(Region.fromSettings());
  // .then((_) =>
  EventHistory.load();
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: SnackbarGlobal.key,
      title: 'eBrevet Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: HomePage(),
    );
  }
}


class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    var style = TextStyle(
      fontSize: 20,
    );

    return Scaffold(
        appBar: AppBar(
          title: Text(
            'eBrevet Card',
            //style: TextStyle(fontSize: 14),
          ),
        ),
        body: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Center(
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(flex: 4),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                            builder: (context) =>
                                EventsPage(), // will implicitly ride event just activated
                          ))
                          .then((value) => setState(
                                () {},
                              )),
                      child: Text(
                        'Future Events',
                        style: style,
                      )),
                  Spacer(flex: 1),
                  ElevatedButton(
                      onPressed: (Current.isActivated ||
                              Current.outcomes?.overallOutcome ==
                                  OverallOutcome.active)
                          ? () => Navigator.of(context)
                              .push(MaterialPageRoute(
                                builder: (context) =>
                                    RidePage(), // will implicitly ride event just activated
                              ))
                              .then((value) => setState(
                                    () {},
                                  ))
                          : null,
                      child: Text(
                        'Current Event',
                        style: style,
                      )),
                  Spacer(flex: 1),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                            builder: (context) =>
                                PastEventsPage(), // will implicitly ride event just activated
                          ))
                          .then((value) => setState(
                                () {},
                              )),
                      child: Text(
                        'Past Events',
                        style: style,
                      )),
                  Spacer(flex: 1),
                  ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                SettingsPage(), // will implicitly ride event just activated
                          )).then((value) => setState(
                                () {},
                              )),
                      child: Text(
                        'Settings',
                        style: style,
                      )),
                  // Spacer(flex: 1),
                  // ElevatedButton(
                  //     onPressed: () =>
                  //         Navigator.of(context).push(MaterialPageRoute(
                  //           builder: (context) =>
                  //               TestPage(), // will implicitly ride event just activated
                  //         )),
                  //     child: Text(
                  //       'Test',
                  //       style: style,
                  //     )),
                  Spacer(flex: 4),
                ],
              ),
            ),
          ),
        ));
  }
}
