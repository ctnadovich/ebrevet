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

import 'package:ebrevet_card/mylogger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'snackbarglobal.dart';
import 'scheduled_events.dart';
import 'event_card.dart';
import 'app_settings.dart';
import 'day_night.dart';
// import 'ticker.dart';
import 'time_till.dart';
import 'side_menu.dart';
import 'settings_page.dart';
import 'location.dart';
import 'event.dart';

class ScheduledEventsPage extends StatefulWidget {
  final EventFilter eventFilter;
  const ScheduledEventsPage({super.key, this.eventFilter = EventFilter.future});
  @override
  State<ScheduledEventsPage> createState() => _ScheduledEventsPageState();
}

class _ScheduledEventsPageState extends State<ScheduledEventsPage> {
  @override
  void initState() {
    super.initState();
    checkPerms();
  }

  void checkPerms() async {
    bool tryAgain = true;
    String? permStatus;

    while (tryAgain) {
      permStatus = await RiderLocation.checkLocationPermissions();
      if (permStatus == null) {
        tryAgain = false;
      } else {
        // MyLogger.entry('GPS Check Failed: $permStatus');
        tryAgain = await openPermErrorDialog(permStatus);
        MyLogger.entry(
            "GPS Fail Dialog: ${tryAgain ? 'try again' : 'give up'}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var dayNight = context.watch<DayNight>();

    final eventFilter = widget.eventFilter;
    final eventFilterText = eventFilter.description;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(eventFilterText),
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
        child: (AppSettings.areRequiredSettingsSet)
            ? const LatestEventList()
            : RequiredAppSettings(
                collapsed: false,
                onContinue: () => setState(() {}),
              ),
      ),
    );
  }

  Future<bool> openPermErrorDialog(String msg) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error,
          size: 64,
        ),
        title: const Text("Can't Get Location"),
        content: const Text('I tried to request permission to use the '
            'GPS on this phone to determine your Location, but the request was '
            'DENIED. This app can\'t work without Location permission. '
            'Make sure Location permission is granted to this '
            'app in App Settings.'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('TRY AGAIN')),
          TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('IGNORE'))
        ],
      ),
    );
  }
}

class LatestEventList extends StatefulWidget {
  const LatestEventList({
    super.key,
  });

  @override
  State<LatestEventList> createState() => _LatestEventListState();
}

class _LatestEventListState extends State<LatestEventList> {
  bool fetchingFromServerNow = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: AppSettings.timeRefreshPeriod),
      (timer) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BuildContext context) {
    var events = ScheduledEvents.events;
    var sourceSelection = context.watch<SourceSelection>();

    return Stack(children: [
      ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: eventListHeader(sourceSelection),
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
        ),
    ]);
  }

  List<Widget> eventListHeader(SourceSelection sourceSelection) {
    var ttLastRefreshed = ScheduledEvents.lastRefreshed != null
        ? TimeTill(ScheduledEvents.lastRefreshed!)
        : null;

    return [
      Row(
        children: [
          const Spacer(
            flex: 5,
          ),
          ElevatedButton.icon(
            onPressed: () {
              SnackbarGlobal.show(
                  'Updating events for ${sourceSelection.eventInfoSource.fullDescription}... (This may take a few seconds.)');
              setState(() {
                fetchingFromServerNow = true;
              });

              ScheduledEvents.refreshScheduledEventsFromServer(
                      sourceSelection.eventInfoSource, context)
                  .then(
                      (value) => setState(() => fetchingFromServerNow = false));

              //Future.delayed(const Duration(seconds: 5))
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Update event data'),
          ),
          const Spacer(),
          IconButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                    builder: (context) => const EventSearchSettingsPage(),
                  ))
                  .then((value) => setState(() {})),
              icon: const Icon(Icons.manage_search)),
          const Spacer(
            flex: 5,
          ),
        ],
      ),

      //Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      // const Spacer(),
      //Expanded(
      //flex: 20,
      //  child:
      if (sourceSelection.eventInfoSource != ScheduledEvents.eventInfoSource)
        Text(
          "Next update from "
          "${sourceSelection.eventInfoSource.fullDescription}",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      //),
      // const Spacer()
      //]),
      // if (FutureEvents.eventInfoSource != null) ...[
      //   const Text('List of events for:'),
      //   Text('${FutureEvents.eventInfoSource!.description}'),
      //   Text(
      //     '${FutureEvents.eventInfoSource!.subDescription}',
      //     style: Theme.of(context).textTheme.bodySmall,
      //   ),
      // ],
      Text(
        ttLastRefreshed != null
            ? 'Event data updated: ${ttLastRefreshed.interval} ${ttLastRefreshed.unit}${ttLastRefreshed.ago}'
            : 'No event data. Update Now!',
      ),
      const Text(
        'Update event data before you ride!',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ];
  }
}

class EventSearchSettingsPage extends StatefulWidget {
  const EventSearchSettingsPage({
    super.key,
  });

  @override
  State<EventSearchSettingsPage> createState() =>
      _EventSearchSettingsPageState();
}

class _EventSearchSettingsPageState extends State<EventSearchSettingsPage> {
  @override
  Widget build(BuildContext context) {
    var dayNight = context.watch<DayNight>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Info Source',
          //style: TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
              tooltip: 'Event Info Source',
              icon: dayNight.icon,
              onPressed: () {
                dayNight.toggleMode();
              })
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: const EventSearchSettings(
          initiallyExpanded: true,
        ),
      ),
    );
  }
}
