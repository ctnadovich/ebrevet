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

import 'rider.dart';
import 'region.dart';
import 'event.dart';
import 'outcome.dart';


class PastEventsPage extends StatefulWidget {
  @override
  State<PastEventsPage> createState() => _PastEventsPageState();
}

class _PastEventsPageState extends State<PastEventsPage> {
  @override
  Widget build(BuildContext context) {
    // var events = FutureEvents.events;

    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Past Events',
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

                Text('Past events for: ${Rider.fromSettings().firstLastRUSA}'),

                for(var pe in EventHistory.pastEventList) PastEventCard(pe.event),


              ],
            ),
          ),
        ));
  }
}

  class PastEventCard extends StatelessWidget {
  final Event event;

  const PastEventCard(this.event); 

  
  @override
  Widget build(BuildContext context) {

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
            ],
          ),
          SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }



}
