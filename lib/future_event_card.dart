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

import 'package:ebrevet_card/cert_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'snackbarglobal.dart';
import 'future_events.dart';
import 'event.dart';
import 'outcome.dart';
import 'ride_page.dart';
import 'region.dart';
import 'event_history.dart';
import 'current.dart';
import 'signature.dart';
import 'app_settings.dart';
import 'mylogger.dart';

class EventCard extends StatefulWidget {
  final Event event;

  const EventCard(this.event, {super.key});

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

    final bool isOutcomeFullyUploaded =
        pe?.isCurrentOutcomeFullyUploaded ?? false;

    final isStartable = widget.event.isStartable;
    final isPreridable = widget.event.isPreridable;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.pedal_bike),
            title: showEventName(widget.event),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(regionName),
                Text('${widget.event.startCity}, ${widget.event.startState}'),
                Text('${widget.event.dateTime} (${widget.event.statusText})'),
                Text('Latest Cue Ver: ${widget.event.cueVersionString}'),
                // const Text('Organizer (Call if abandoning):'),
                // Text(
                //     '  ${widget.event.organizerName} ${widget.event.organizerPhone}'),
              ],
            ),
          ),
          // Row(
          //   // mainAxisAlignment: MainAxisAlignment.end,
          //   children: <Widget>[
          //     Container(
          //       padding: EdgeInsets.fromLTRB(16, 16, 0, 8),
          //       child:

          Column(
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                  ),
                  Text(
                    overallOutcomeDescriptionInHistory,
                    style: overallOutcomeInHistory == OverallOutcome.active
                        ? const TextStyle(
                            fontWeight: FontWeight.bold,
                            // decoration: TextDecoration.underline,
                          )
                        : null,
                  ),
                  overallOutcomeInHistory == OverallOutcome.finish
                      ? Text(" ${EventHistory.getElapsedTimeString(eventID)}")
                      : const SizedBox.shrink(),
                  overallOutcomeInHistory == OverallOutcome.active
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              pe!.overallOutcome = OverallOutcome.dnf;
                              // pe can't be null because overallOutcomeInHistory wasn't unknown
                            });
                            EventHistory.save();
                            Current.deactivate();
                          },
                          icon: const Icon(Icons.cancel),
                          tooltip: 'Abandon the event',
                        )
                      : const SizedBox.shrink(),
                  //     ],
                  //   ),
                  // ),
                  const Spacer(),
                  (isStartable ||
                          isPreridable ||
                          overallOutcomeInHistory != OverallOutcome.dns)
                      ? rideButton(context, pe)
                      : const SizedBox.shrink(),
                  const SizedBox(width: 8),
                ],
              ),
              (overallOutcomeInHistory == OverallOutcome.dns)
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Text(pe?.checkInFractionString ?? ''),
                        Text(
                          pe?.isFullyUploadedString ?? '',
                          style: TextStyle(
                              fontWeight: isOutcomeFullyUploaded
                                  ? FontWeight.normal
                                  : FontWeight.bold),
                        ),
                      ],
                    ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }

  TextButton rideButton(BuildContext context, PastEvent? pe) {
    final isPreride = widget.event.isPreridable;
    // final bool isOutcomeFullyUploaded =
    //     pe?.isCurrentOutcomeFullyUploaded ?? false;
    // final eventID = widget.event.eventID;
    // final pe = EventHistory.lookupPastEvent(eventID);
    final OverallOutcome overallOutcomeInHistory =
        pe?.outcomes.overallOutcome ?? OverallOutcome.dns;

    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
      ),
      onPressed: () async {
        if (AppSettings.isRusaIDSet == false) {
          SnackbarGlobal.show("Can't RIDE. Is RUSA ID set?");
        } else {
          if (overallOutcomeInHistory == OverallOutcome.dns) {
            final startCode = await openStartBrevetDialog();
            final msg = validateStartCode(startCode, widget.event);
            if (null != msg) {
              SnackbarGlobal.show(msg);
              return;
            }
          }

          if (context.mounted) {
            if (overallOutcomeInHistory != OverallOutcome.finish) {
              Current.activate(widget.event, AppSettings.rusaID,
                  isPreride: isPreride);
            }
            Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (context) =>
                      overallOutcomeInHistory != OverallOutcome.finish
                          ? const RidePage()
                          : CertificatePage(
                              pe!), // will implicitly ride event just activated
                ))
                .then((_) => setState(() {}));
          } else {
            MyLogger.entry("Not mounted!?");
          }
        }
      },
      child: Text(overallOutcomeInHistory == OverallOutcome.finish
          ? "VIEW"
          : (overallOutcomeInHistory == OverallOutcome.active
              ? "CONTINUE RIDE"
              : (isPreride ? 'PRERIDE' : 'RIDE'))),
    );
  }

  String? validateStartCode(String? s, Event event) {
    if (s == null || s.isEmpty) return "Missing start code";
    if (false == AppSettings.isRusaIDSet) return "Rider not set.";
    if (FutureEvents.region == null) return "No region. ";

    var startCode = Signature.substituteZeroOneXY(s.toUpperCase());
    var magicCode =
        Signature.substituteZeroOneXY(AppSettings.magicStartCode.toUpperCase());

    if (startCode == magicCode) return null;

    var rusaID = AppSettings.rusaID;

    var cueVersion = event.cueVersion.toString();

    var signature = Signature(
        data: cueVersion, riderID: rusaID, event: event, codeLength: 4);

    var validCode = Signature.substituteZeroOneXY(signature.text.toUpperCase());

    if (validCode != startCode) {
      MyLogger.entry(
          "Invalid Start Code $startCode; Valid code is '$validCode'");
      return "Invalid Start Code.";
    }

    return null;
  }

  Future<String?> openStartBrevetDialog() => showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enter Brevet Start Code'),
          content: TextField(
            decoration:
                const InputDecoration(hintText: 'Enter code from brevet card'),
            autofocus: true,
            controller: controller,
            onSubmitted: (_) => submitStartBrevetDialog(),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  submitStartBrevetDialog();
                },
                child: const Text('SUBMIT'))
          ],
        ),
      );

  void submitStartBrevetDialog() {
    Navigator.of(context).pop(controller.text);
    controller.clear();
  }

  Widget showEventName(Event event) {
    return GestureDetector(
      onTap: () {
        openEventNameDialog(event);
      },
      child: Text(
        event.nameDist,
        style: TextStyle(
            fontSize:
                Theme.of(context).primaryTextTheme.bodyLarge?.fontSize ?? 16,
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Future openEventNameDialog(Event event) {
    // final eventID = widget.event.eventID;
    final we = event;
    final regionID = we.regionID;
    final region = Region(regionID: regionID);
    final regionName = region.regionName;
    final clubName = region.clubName;

    // note the scary ! after bodyLarge
    final bigItalic = Theme.of(context)
        .textTheme
        .bodyLarge!
        .copyWith(fontStyle: FontStyle.italic);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.event.nameDist),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${we.eventSanction} ${we.eventType}', style: bigItalic),
            Text('Region: $regionName'),
            Text('Club: $clubName'),
            Text('Location: ${we.startCity}, ${we.startState}'),
            Text('Start: ${we.dateTime} (${we.statusText})'),
            Text('Latest Cue Ver: ${we.cueVersionString}'),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                const Spacer(
                  flex: 1,
                ),
                ElevatedButton(
                    onPressed: () => we.eventURL.isEmpty
                        ? null
                        : launchUrl(Uri.parse(we.eventInfoUrl)),
                    child: const Text("Event Website")),
                const Spacer(
                  flex: 1,
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'In case of emergency, CALL 911.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
                'If abandonning or riding beyond the cutoff, call the organizer: ${we.organizerName} (${we.organizerPhone})')
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'))
        ],
      ),
    );
  }
}
