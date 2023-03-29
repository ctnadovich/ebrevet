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

import 'package:ebrevet_card/app_settings.dart';
import 'package:provider/provider.dart';

import 'future_events_page.dart';
import 'day_night.dart';
import 'past_events_page.dart';

// THIS PAGE IS NOT USED

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
      body: mainMenu(context),
      // body: (AppSettings.isRusaIDSet)
      //     ? mainMenu(context)
//          : requiredSettings(), //  rusaIDField(),
    );
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
                    'Events to Ride',
                    style: style,
                  )),
              // const Spacer(flex: 1),
              // ElevatedButton(
              //     onPressed: (Current.isActivated ||
              //             Current.outcomes?.overallOutcome ==
              //                 OverallOutcome.active)
              //         ? () => Navigator.of(context)
              //             .push(MaterialPageRoute(
              //               builder: (context) =>
              //                   const RidePage(), // will implicitly ride event just activated
              //             ))
              //             .then((value) => setState(
              //                   () {},
              //                 ))
              //         : null,
              //     child: Text(
              //       'Current Event',
              //       style: style,
              //     )),
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
