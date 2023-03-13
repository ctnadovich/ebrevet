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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_settings.dart';
import 'region.dart';
import 'event.dart';
import 'outcome.dart';
import 'day_night.dart';

class PastEventsPage extends StatefulWidget {
  @override
  State<PastEventsPage> createState() => _PastEventsPageState();
}

class _PastEventsPageState extends State<PastEventsPage> {
  @override
  Widget build(BuildContext context) {
    // var events = FutureEvents.events;
    var dayNight = context.watch<DayNight>();

    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Past Events',
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
                // SizedBox(height: 2),

                // Text('Past events for: ${AppSettings.rusaID}'),

                for (var pe in EventHistory.pastEventList)
                  pastEventCard(context, pe.event),
              ],
            ),
          ),
        ));
  }


Widget pastEventCard(BuildContext context, Event event) {

    final eventID = event.eventID;
    final pe = EventHistory.lookupPastEvent(eventID);
    // var eventInHistory = pe?.event;
    final OverallOutcome overallOutcomeInHistory =
        pe?.outcomes.overallOutcome ?? OverallOutcome.dns;
    final String overallOutcomeDescriptionInHistory =
        overallOutcomeInHistory.description;
    final clubName = Region(regionID: event.regionID).clubName;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.pedal_bike),
            title: Text(event.nameDist),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clubName),
                Text('${event.startCity}, ${event.startState}'),
                Text('${event.dateTime}'),
              ],
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 16,
              ),
              Text(
                overallOutcomeDescriptionInHistory,
                style: overallOutcomeInHistory == OverallOutcome.active
                    ? TextStyle(
                        fontWeight: FontWeight.bold,
                        // decoration: TextDecoration.underline,
                      )
                    : null,
              ),
              overallOutcomeInHistory == OverallOutcome.finish
                  ? Text(" ${EventHistory.getElapsedTimeString(eventID)}")
                  : SizedBox.shrink(),
              Spacer(),
              viewButton(context, eventID),
              SizedBox(
                width: 4,
              ),
              deleteButton(context, eventID),
              SizedBox(
                width: 4,
              ),
            ],
          ),
          SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }

  Widget deleteButton(BuildContext context, String eventID) {
    final pe = EventHistory.lookupPastEvent(eventID);
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
      ),
      onPressed: () async {
        confirmDeleteDialog(context, pe!);
      },
      child: (pe?.outcomes.overallOutcome == OverallOutcome.dns)
          ? SizedBox.shrink()
          : Text("DELETE"),
    );
  }

void confirmDeleteDialog(BuildContext context, PastEvent pe) {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
              return AlertDialog(
      title: const Text('Please Confirm'),
      content:  Text('Delete the ${pe.event.nameDist}?'),
      actions: [
        // The "Yes" button
        TextButton(
            onPressed: () {
              // Remove the box
              setState(() {
                EventHistory.deletePastEvent(pe);
              });

              // Close the dialog
              Navigator.of(context).pop();
            },
            child: const Text('Yes')),
        TextButton(
            onPressed: () {
              // Close the dialog
              Navigator.of(context).pop();
            },
            child: const Text('No'))
      ],
    );
  });}

  Widget viewButton(BuildContext context, String eventID) {
    final pe = EventHistory.lookupPastEvent(eventID);
    final OverallOutcome overallOutcomeInHistory =
        pe?.outcomes.overallOutcome ?? OverallOutcome.dns;

    if (overallOutcomeInHistory != OverallOutcome.finish) {
      return SizedBox.shrink();
    }

    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
      ),
      onPressed: () async {
        if (context.mounted) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ViewPage(pe!),
          ));
        } else {
          print("Not mounted!?");
        }
      },
      child: Text("VIEW"),
    );
  }
}


class ViewPage extends StatelessWidget {
  final PastEvent pastEvent;

  const ViewPage(this.pastEvent);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            pastEvent.event.nameDist,
            //style: TextStyle(fontSize: 14),
          ),
        ),
        body: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Center(
            child: ListView(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SizedBox(height: 2),
                Text(
                  (pastEvent.isPreride)
                      ? 'Volunteer Preride'
                      : 'Scheduled Brevet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Overall result: ${pastEvent.overallOutcomeDescription}'),
                Text('Elapsed time: ${pastEvent.elapsedTimeString}'),

                for (var checkIn in pastEvent.outcomes.checkInTimeList)
                  checkInCard(checkIn),
              ],
            ),
          ),
        ));
  }

  // TODO Pretty this up and add more analytics

  // TODO should show download state and possibly offer download button

  Widget checkInCard(List<String> checkIn) {
    var controlIndex = int.parse(checkIn[0]);
    var citString = DateTime.parse(checkIn[1]).toLocal().toIso8601String();
    var ciDate = citString.substring(0, 10);
    var ciTime = citString.substring(11, 16);
    var event = pastEvent.event;
    var control = event.controls[controlIndex];
    var courseMile = control.distMi;
    var controlName = control.name;
    return Card(
      child: ListTile(
        leading: Icon(controlIndex == event.startControlKey
            ? Icons.play_arrow
            : (controlIndex == event.finishControlKey
                ? Icons.stop
                : Icons.pedal_bike)),
        title: Text(controlName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(control.address),
            Text(
                'Control ${controlIndex + 1} ($courseMile mi): $ciDate @ $ciTime'),
          ],
        ),
      ),
    );
  }
}
