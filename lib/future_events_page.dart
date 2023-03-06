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
import 'snackbarglobal.dart';
import 'future_events.dart';
import 'event.dart';
import 'outcome.dart';
import 'ride_page.dart';
// import 'app_settings.dart';
import 'rider.dart';
import 'region.dart';
// import 'control.dart';
import 'event_history.dart';
import 'current.dart';
import 'signature.dart';

class TestPage extends StatefulWidget {
  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    return (busy)
        ? CircularProgressIndicator()
        : ElevatedButton(
            onPressed: () {
              setState(() {
                busy = true;
              });
              Future.delayed(const Duration(seconds: 5))
                  .then((value) => setState(
                        () {
                          busy = false;
                        },
                      ));
            },
            child: Text('PRESS ME'),
          );
  }
}

class EventsPage extends StatefulWidget {
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  // Future<DateTime>? lastTime;

  bool fetchingFromServerNow = false;

  @override
  void initState() {
    // This will throw error the first time because Rider isn't set
    // FutureEvents.refreshEvents(Rider.fromSettings(), Region.fromSettings());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var events = FutureEvents.events;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Future Events',
          //style: TextStyle(fontSize: 14),
        ),
      ),
      // body: ValueListenableBuilder(
      //     valueListenable: FutureEvents.refreshCount,
      //     builder: (context, value, child) {
      body: Stack(children: [
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
                        SnackbarGlobal.show('Refreshing Future Events...');
                        setState(() {
                          fetchingFromServerNow = true;
                        });
                        FutureEvents.refreshEventsFromServer(
                                Rider.fromSettings(), Region.fromSettings())
                            // Future.delayed(const Duration(seconds: 5))
                            .then((value) =>
                                setState(() => fetchingFromServerNow = false));
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh Events from Server'),
                    ),
                    Text(
                        'Future events in region: ${Region.fromSettings().clubName}'),
                    Text('Last refreshed: ${FutureEvents.lastRefreshedStr}'),
                    Text('Rider: ${Rider.fromSettings().firstLastRUSA}'),
                    ...events.map((e) => EventCard(e)),
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
          const Center(
            child: CircularProgressIndicator(),
          ),
      ]),
    );
  }
}

class EventCard extends StatefulWidget {
  final Event event;

  const EventCard(this.event); 

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late TextEditingController controller;
  String startCode = '';

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
    final eventID = widget.event.eventID;
    final regionID = widget.event.regionID;
    final regionName = Region(regionID: regionID).clubName;
    final pe = EventHistory.lookupPastEvent(eventID);
    // var eventInHistory = pe?.event;
    final OverallOutcome overallOutcomeInHistory =
        pe?.outcomes.overallOutcome ?? OverallOutcome.dns;
    final String overallOutcomeDescriptionInHistory =
        overallOutcomeInHistory.description;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.pedal_bike),
            title: Text(widget.event.nameDist),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(regionName),
                Text('${widget.event.startCity}, ${widget.event.startState}'),
                Text('${widget.event.dateTime} (${widget.event.statusText})'),
                Text('Organizer: ${widget.event.organizerName} (${widget.event.organizerPhone})'),
                Text('Latest Cue Ver: ${widget.event.cueVersionString}'),
              ],
            ),
          ),
          // Row(
          //   // mainAxisAlignment: MainAxisAlignment.end,
          //   children: <Widget>[
          //     Container(
          //       padding: EdgeInsets.fromLTRB(16, 16, 0, 8),
          //       child:

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
              overallOutcomeInHistory == OverallOutcome.active
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          pe!.overallOutcome = OverallOutcome.dnf;
                          // pe can't be null because overallOutcomeInHistory wasn't unknown
                        });
                        EventHistory.save();
                      },
                      icon: const Icon(Icons.cancel),
                      tooltip: 'Abandon the event',
                    )
                  : SizedBox.shrink(),
              //     ],
              //   ),
              // ),
              Spacer(),
              (widget.event.isStartable || widget.event.isPreridable)
                  ? rideButton(context)
                  : SizedBox.shrink(),
              const SizedBox(width: 8),
            ],
          ),
          SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }

  TextButton rideButton(BuildContext context) {

    final isPreride = widget.event.isPreridable;  
    final eventID = widget.event.eventID;
    final pe = EventHistory.lookupPastEvent(eventID);
    final OverallOutcome overallOutcomeInHistory =
        pe?.outcomes.overallOutcome ?? OverallOutcome.dns;

    return TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () async {
                      if (Rider.isSet == false ||
                          FutureEvents.region == null) {
                        SnackbarGlobal.show(
                            "Can't RIDE. Is Rider Name, RUSA ID, and Region set?");
                      } else {
                        if (overallOutcomeInHistory == OverallOutcome.dns) {
                          final startCode = await openStartBrevetDialog();
                          final msg =
                              validateStartCode(startCode, widget.event);
                          if (null != msg) {
                            SnackbarGlobal.show(msg);
                            return;
                          }
                        }

                        if (context.mounted) {
                          if (overallOutcomeInHistory !=
                              OverallOutcome.finish) {
                            Current.activate(widget.event,
                                Rider.fromSettings().rusaID, 
                                isPreride: isPreride);
                          }
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                                builder: (context) =>
                                    RidePage(), // will implicitly ride event just activated
                              ))
                              .then((_) => setState(() {}));
                        } else {
                          print("Not mounted!?");
                        }
                      }
                    },
                    child: Text(isPreride?'PRERIDE':'RIDE'),
                  );
  }

  String? validateStartCode(String? startCode, Event event) {
    if (startCode == null || startCode.isEmpty) {
      return "Missing start code";
    }

    if(startCode==Region.magicStartCode) return null;

    if (false == Rider.isSet) return "Rider not set.";
    if (FutureEvents.region == null) return "No region. ";

    var rider = Rider.fromSettings().rusaID;

    var signature = Signature(
        riderID: rider,
        event: event,
        codeLength: 4);

    var validCode = signature.text.toUpperCase();

    if (validCode != startCode.toUpperCase()) {
      print("Invalid Start Code $startCode; Valid code is '$validCode'");
      return "Invalid Start Code.";
    }

    return null;
  }

  Future<String?> openStartBrevetDialog() => showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enter Brevet Start Code'),
          content: TextField(
            decoration:
                InputDecoration(hintText: 'Enter code from brevet card'),
            autofocus: true,
            controller: controller,
            onSubmitted: (_) => submitStartBrevetDialog(),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  submitStartBrevetDialog();
                },
                child: Text('SUBMIT'))
          ],
        ),
      );

  void submitStartBrevetDialog() {
    Navigator.of(context).pop(controller.text);
    controller.clear();
  }
}
