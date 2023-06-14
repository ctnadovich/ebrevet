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

import 'package:ebrevet_card/cert_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'snackbarglobal.dart';
import 'future_events.dart';
import 'event.dart';
import 'outcome.dart';
import 'ride_page.dart';
import 'region.dart';
import 'event_history.dart';
import 'past_event.dart';
import 'signature.dart';
import 'app_settings.dart';
import 'mylogger.dart';
import 'control_state.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final bool? hasDelete;
  final Function? onDelete;

  const EventCard(this.event, {super.key, this.hasDelete, this.onDelete});

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
    context.watch<ControlState>();
    final event = widget.event;

    final regionName = Region(regionID: event.regionID).clubName;
    final pe = EventHistory.lookupPastEvent(event.eventID);
    final OverallOutcome overallOutcomeInHistory =
        pe?.outcomes.overallOutcome ?? OverallOutcome.dns;
    final String overallOutcomeDescriptionInHistory =
        overallOutcomeInHistory.description;
    final bool isOutcomeFullyUploaded =
        pe?.isCurrentOutcomeFullyUploaded ?? false;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.pedal_bike),
            trailing: widget.hasDelete == true
                ? IconButton(
                    onPressed: () async {
                      confirmDeleteDialog(context, pe!);
                    },
                    icon: const Icon(Icons.delete))
                : null,
            title: showEventName(event),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(regionName),
                Text('${event.startCity}, ${event.startState}'),
                if (event.startTimeWindow.onTime != null)
                  Text('${widget.event.dateTime} (${event.eventStatusText})'),
                Text('Latest Cue Ver: ${event.cueVersionString}'),
              ],
            ),
          ),
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
                          )
                        : null,
                  ),
                  overallOutcomeInHistory == OverallOutcome.finish
                      ? Text(
                          " ${EventHistory.getElapsedTimeString(event.eventID)}")
                      : const SizedBox.shrink(),
                  overallOutcomeInHistory == OverallOutcome.active
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              pe!.overallOutcome = OverallOutcome.dnf;
                              // pe can't be null because overallOutcomeInHistory wasn't unknown
                            });
                            EventHistory.save();
                            // Current.deactivate();
                          },
                          icon: const Icon(Icons.cancel),
                          tooltip: 'Abandon the event',
                        )
                      : const SizedBox.shrink(),
                  //     ],
                  //   ),
                  // ),
                  const Spacer(),
                  rideButton(context, event, pastEvent: pe),
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

  void confirmDeleteDialog(BuildContext context, PastEvent pe) {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Please Confirm'),
            content: Text('Delete the ${pe.event.nameDist}?'),
            actions: [
              // The "Yes" button
              TextButton(
                  onPressed: () {
                    // Remove the box
                    EventHistory.deletePastEvent(pe);

                    // Close the dialog
                    Navigator.of(context).pop();
                    if (widget.onDelete != null) widget.onDelete!();
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
        });
  }

  Widget rideButton(BuildContext context, Event event, {PastEvent? pastEvent}) {
    var controlState = context
        .read<ControlState>(); // So addActivate can dirty the control card

    final isStartable = event.isStartable;
    final isPreridable = event.isPreridable;
    final OverallOutcome overallOutcomeInHistory =
        pastEvent?.outcomes.overallOutcome ?? OverallOutcome.dns;
    final notYetStarted = overallOutcomeInHistory == OverallOutcome.dns;
    final isFinished = overallOutcomeInHistory == OverallOutcome.finish;
    final notYetFinished = !isFinished;
    final isRiding = overallOutcomeInHistory == OverallOutcome.active;

    String? buttonText;
    var isPreride = false;
    if (isFinished) {
      buttonText = "CERTIFICATE";
    } else if (isRiding) {
      buttonText = "CONTINUE RIDE";
    } else if (isPreridable) {
      buttonText = "PRE-RIDE";
      isPreride = true;
    } else if (isStartable) {
      buttonText = "RIDE";
    }

    if (buttonText == null) return const SizedBox.shrink(); // No button

    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
      ),
      onPressed: () async {
        if (AppSettings.isRusaIDSet == false) {
          SnackbarGlobal.show("Can't RIDE. Rider ID not set.");
        } else {
          // If we did not (yet) start, then validate start.

          if (notYetStarted) {
            final startCode = await openStartBrevetDialog();
            final msg = validateStartCode(startCode, event);
            if (null != msg) {
              SnackbarGlobal.show(msg);
              return;
            }
          }

          // OK to start, or re-start. Which is it?

          if (context.mounted) {
            // or will get 'don't use context across async gaps warning

            if (notYetFinished) {
              if (pastEvent != null) {
                EventHistory.addActivate(event); // re-activate
              } else {
                pastEvent = EventHistory.addActivate(widget.event,
                    riderID: AppSettings.rusaID.value,
                    startStyle: isPreride
                        ? StartStyle.preRide
                        : event.startTimeWindow.startStyle,
                    controlState: controlState);
              }
            }

            assert(pastEvent !=
                null); // by now there must be an activated event pastEvent
            // either created by the start above
            // or passed in as a parameter for

            Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (context) => overallOutcomeInHistory !=
                          OverallOutcome.finish
                      ? RidePage(pastEvent!)
                      : CertificatePage(
                          pastEvent!), // will implicitly ride event just activated
                ))
                .then((_) => setState(() {}));
          } else {
            MyLogger.entry("Not mounted!?");
          }
        }
      },
      child: Text(buttonText),
    );
  }

  String? validateStartCode(String? s, Event event) {
    if (s == null || s.isEmpty) return "Missing start code";
    if (false == AppSettings.isRusaIDSet) return "Rider not set.";
    if (FutureEvents.eventInfoSource == null) return "No event authority. ";

    var offeredCode = Signature.substituteZeroOneXY(s.toUpperCase());
    var magicCode =
        Signature.substituteZeroOneXY(AppSettings.magicStartCode.toUpperCase());

    if (offeredCode == magicCode) return null;

    var validCode = Signature.startCode(event, AppSettings.rusaID.value).xyText;
    if (validCode == offeredCode) return null;

    var cueVersion = event.cueVersion - 1;
    while (cueVersion >= 0) {
      var oldCode = Signature.startCode(event, AppSettings.rusaID.value,
              cueVersion: cueVersion)
          .xyText;
      if (offeredCode == oldCode) {
        SnackbarGlobal.show("Start Code from OLD cue version.");
        return null;
      }
      cueVersion--;
    }
    MyLogger.entry(
        "Invalid Start Code $offeredCode; Valid code is '$validCode'; ");
    return "Invalid Start Code.";
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
            if (we.startTimeWindow.onTime != null)
              Text('Start: ${we.dateTime} (${we.eventStatusText})'),
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
                    onPressed: () => we.eventInfoUrl.isEmpty
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
