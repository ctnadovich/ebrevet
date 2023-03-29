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

import 'package:ebrevet_card/event.dart';
import 'package:ebrevet_card/past_events_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:url_launcher/url_launcher.dart';

import 'snackbarglobal.dart';
import 'future_events.dart';
import 'event_card.dart';
import 'region.dart';
import 'app_settings.dart';
import 'day_night.dart';
import 'ticker.dart';
import 'time_till.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late TextEditingController controller;

  bool fetchingFromServerNow = false;
  Ticker ticker = Ticker();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();

    ticker.init(
      period: AppSettings.timeRefreshPeriod,
      onTick: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    ticker.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var events = FutureEvents.events;
    var dayNight = context.watch<DayNight>();
    var ttLastRefreshed = FutureEvents.lastRefreshed != null
        ? TimeTill(FutureEvents.lastRefreshed!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'eBrevet',
        ),
        actions: [
          IconButton(
              icon: dayNight.icon,
              onPressed: () {
                dayNight.toggleMode();
              })
        ],
      ),

// TODO Menu items should have bigger font and icons

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: const Text('eBrevet Main Menu'),
            ),
            ListTile(
              title: const Text('Past Events'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context)
                    .push(MaterialPageRoute(
                  builder: (context) => const PastEventsPage(),
                ))
                    .then((value) {
                  setState(
                    () {},
                  );
                });
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context)
                    .push(MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ))
                    .then((value) {
                  setState(
                    () {},
                  );
                });
              },
            ),
            ListTile(
              title: const Text('About eBrevet'),
              onTap: () {
                Navigator.pop(context);
                aboutDialog();
              },
            ),
          ],
        ),
      ),

      body: (AppSettings.isRusaIDSet) //  && AppSettings.rusaID!='99999')
          ? mainEventsPage(context, ttLastRefreshed, events)
          : requiredSettings(), //  rusaIDField(),
    );
  }

  void aboutDialog() {
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

  Stack mainEventsPage(
      BuildContext context, TimeTill? ttLastRefreshed, List<Event> events) {
    return Stack(children: [
      Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Center(
          child: ListView(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SizedBox(height: 2),
              ElevatedButton.icon(
                onPressed: () {
                  SnackbarGlobal.show(
                      'Updating events from server... (This may take a few seconds.)');
                  setState(() {
                    fetchingFromServerNow = true;
                  });
                  FutureEvents.refreshEventsFromServer(Region.fromSettings())
                      // Future.delayed(const Duration(seconds: 5))
                      .then((value) =>
                          setState(() => fetchingFromServerNow = false));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Update Events from Server'),
              ),
              Text(
                'Future events for: ${Region.fromSettings().clubName}',
                textAlign: TextAlign.center,
              ),
              Text(
                ttLastRefreshed != null
                    ? 'Last updated: ${ttLastRefreshed.interval} ${ttLastRefreshed.unit}${ttLastRefreshed.ago}'
                    : 'Update Events Now!',
                textAlign: TextAlign.center,
              ),
              const Text(
                'Update events before you ride!',
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              ...events.map((e) => EventCard(e)), // All the Event Cards
            ],
          ),
        ),
      ),
      if (fetchingFromServerNow)
        Opacity(
          opacity: 0.6,
          child: ModalBarrier(
            dismissible: false,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
      if (fetchingFromServerNow)
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1),
            duration:
                const Duration(seconds: AppSettings.httpGetTimeoutSeconds),
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
            ),
          ),

          //CircularProgressIndicator(),
        ),
    ]);
  }

  Widget requiredSettings() {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Column(children: [
        const SizedBox(
          height: 10,
        ),
        const Text(
            'Enter your RUSA number and select a Club/Region that supports eBrevet EPP:'),
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
        ElevatedButton(
            onPressed: () => setState(() {}), child: const Text('Continue')),
      ]),
    );
  }

  void submitRusaID() {
    var rusaIDString = controller.text.trim();
    if (AppSettings.isValidRusaID(rusaIDString)) {
      AppSettings.setRusaID(rusaIDString);
      // controller.clear();
    }
  }
}
