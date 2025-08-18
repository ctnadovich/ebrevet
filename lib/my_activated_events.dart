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

import 'package:ebrevet_card/app_settings.dart';
import 'package:ebrevet_card/event_history.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'outcome.dart';
import 'day_night.dart';
import 'mylogger.dart';
import 'cert_page.dart';
import 'event_card.dart';

class MyActivatedEventsPage extends StatefulWidget {
  const MyActivatedEventsPage({super.key});
  @override
  State<MyActivatedEventsPage> createState() => _MyActivatedEventsPageState();
}

class _MyActivatedEventsPageState extends State<MyActivatedEventsPage> {
  @override
  Widget build(BuildContext context) {
    // var events = FutureEvents.events;
    var dayNight = context.watch<DayNight>();

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Rides',
            //style: TextStyle(fontSize: 14),
          ),
          actions: [
            IconButton(
                icon: dayNight.icon,
                onPressed: () {
                  dayNight.toggleMode();
                })
          ],
        ),
        body: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Center(
            child: ListView(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // const SizedBox(height: 2),

                // Text('Past events for: ${AppSettings.rusaID}'),

                for (var pe in EventHistory.pastEventList)
                  EventCard(
                    pe.event,
                    hasDelete: AppSettings.canDeletePastEvents.value,
                    onDelete: () => setState(() {}),
                  ),
              ],
            ),
          ),
        ));
  }

  Widget viewButton(BuildContext context, String eventID) {
    final pe = EventHistory.lookupPastEvent(eventID);
    final OverallOutcome overallOutcomeInHistory =
        pe?.outcomes.overallOutcome ?? OverallOutcome.dns;

    if (overallOutcomeInHistory != OverallOutcome.finish) {
      return const SizedBox.shrink();
    }

    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
      ),
      onPressed: () async {
        if (context.mounted) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => CertificatePage(pe!),
          ));
        } else {
          MyLogger.entry("Not mounted!?");
        }
      },
      child: const Text("CERTIFICATE"),
    );
  }
}
