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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'snackbarglobal.dart';
import 'future_events.dart';
import 'event_card.dart';
import 'region.dart';
import 'app_settings.dart';
import 'day_night.dart';
import 'ticker.dart';
import 'time_till.dart';
import 'required_settings.dart';
import 'side_menu.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});
  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  bool fetchingFromServerNow = false;
  Ticker ticker = Ticker();

  @override
  void initState() {
    super.initState();

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
      drawer: SideMenuDrawer(
        onClose: () => setState(() {}),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Center(
          child: ( // false &&
                  AppSettings
                      .areRequiredSettingsSet) //  && AppSettings.rusaID!='99999')
              ? mainEventsPage(context, ttLastRefreshed, events)
              : const RequiredAppSettings(
                  isExpandable: false,
                ),
        ),
      ),
    );
  }

  Stack mainEventsPage(
      BuildContext context, TimeTill? ttLastRefreshed, List<Event> events) {
    return Stack(children: [
      ListView(
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
                  .then(
                      (value) => setState(() => fetchingFromServerNow = false));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Update event data from Server'),
          ),
          Text(
            // TODO needs to be actual source of events -- not necessarily region

            'Future events for: ${Region.fromSettings().clubName}',
            textAlign: TextAlign.center,
          ),
          Text(
            ttLastRefreshed != null
                ? 'Event data updated: ${ttLastRefreshed.interval} ${ttLastRefreshed.unit}${ttLastRefreshed.ago}'
                : 'Update Event Data Now!',
            textAlign: TextAlign.center,
          ),
          const Text(
            'Update event data before you ride!',
            style: TextStyle(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          ...events.map((e) => EventCard(e)), // All the Event Cards
        ],
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
}
