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
import 'utility.dart';

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
    var controlState = context.watch<ControlState>();
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
            leading: IconButton(
              onPressed: () {
                openEventNameDialog(event);
              },
              icon: const Icon(Icons.info_outline),
            ),
            trailing: widget.hasDelete == true
                ? IconButton(
                    onPressed: () async {
                      var deleted =
                          await confirmDeleteDialog(context, pe!) ?? false;
                      if (deleted) controlState.pastEventDeleted();
                    },
                    icon: const Icon(Icons.delete))
                : null,
            // title: showEventName(event),
            title: Text(
              event.nameDist,
              style: TextStyle(
                fontSize:
                    Theme.of(context).primaryTextTheme.bodyLarge?.fontSize ??
                        16,
                // color: Theme.of(context).colorScheme.primary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(regionName),
                Text('${event.startCity}, ${event.startState}'),
                Row(
                  children: [
                    Text(event.startTimeWindow.startStyle.description),
                    if (event.gravelDistance > 0)
                      Text(' (${event.gravelDistance}K gravel)'),
                  ],
                ),
                if (event.startTimeWindow.onTime != null)
                  Text('${event.dateTime} (${event.eventStatusText})'),
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

  Future<bool?> confirmDeleteDialog(BuildContext context, PastEvent pe) =>
      showDialog<bool>(
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
                      Navigator.of(context).pop(true);
                      if (widget.onDelete != null) widget.onDelete!();
                    },
                    child: const Text('Yes')),
                TextButton(
                    onPressed: () {
                      // Close the dialog
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('No'))
              ],
            );
          });

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

    return ElevatedButton(
      // style: TextButton.styleFrom(
      //   padding: EdgeInsets.zero,
      // ),
      onPressed: () async {
        if (AppSettings.isRusaIDSet == false) {
          SnackbarGlobal.show("Can't RIDE. Rider ID not set.");
        } else {
          // If we did not (yet) start, then validate start.

          if (notYetStarted) {
            final startCode = await getStartCodeDialog();
            final msg = validateStartCode(startCode, event);
            if (null != msg) {
              SnackbarGlobal.show(msg);
              return;
            }
          }

          // OK to start, or re-activate. Unless we are finished!

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

            // Auto first-control check in
            if (pastEvent!.outcomes.checkInTimeList.isEmpty &&
                (isPreridable || isStartable)) {
              // no checkins yet, but starting OK

              switch (pastEvent!.startStyle) {
                case StartStyle.massStart:
                  // Auto checkin for massStart is allowed at any (startable) time, any location
                  pastEvent!.controlCheckIn(
                    control: event.controls[event.startControlKey],
                    comment:
                        "${pastEvent!.startStyle.description}. Automatic Check In",
                    controlState: controlState,
                    checkInTime:
                        event.startTimeWindow.onTime, // check in time override
                  );
                  break;
                case StartStyle.preRide:
                case StartStyle.freeStart:
                case StartStyle.permanent:
                  if (pastEvent!.isControlNearby(event.startControlKey) ||
                      AppSettings.controlProximityOverride.value) {
                    var doAutoCheckin =
                        await confirmAutoCheckinDialog(pastEvent!) ?? false;
                    if (doAutoCheckin) {
                      pastEvent!.controlCheckIn(
                        control: event.controls[event.startControlKey],
                        comment:
                            "${pastEvent!.startStyle.description}. Automatic Check In",
                        controlState: controlState,
                      );
                    }
                  }
                  break;
                default:
                  break;
              }
            }

            // need to save EventHistory now

            EventHistory.save();

            // It seems excessive to save the whole event history
            // every activation, but this certainly does the job.
            // The only time an event can change state is when
            // activated or at a control checkin.

            // once an event is "activated" it gets copied to past events map and becomes immutable -- only the outcome can change
            // so conceivably the preriders could have a different "event" saved than the day-of riders
          }

          assert(pastEvent !=
              null); // by now there must be an activated event pastEvent

          if (context.mounted) {
            // or will get 'don't use context across async gaps warning
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

  Future<bool?> confirmAutoCheckinDialog(PastEvent pe) => showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle, size: 62.0),
          title: const Text('Check In at First Control?'),
          content: Text('Check in NOW at the first control? '
              'Your start time will be immediate (${Utility.toBriefTimeString(DateTime.now().toLocal())})'),
          actions: [
            // The "Yes" button
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Yes')),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('No'))
          ],
        );
      });

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
        "Invalid Start Code $offeredCode; Valid code is '$validCode'; ",
        severity: Severity.hidden);
    return "INVALID Start Code: $offeredCode";
  }

  Future<String?> getStartCodeDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Brevet Start Code '),
        icon: const Icon(Icons.lock_person, size: 128),
        content: TextField(
          decoration: const InputDecoration(
              hintText: 'Enter start code from brevet card'),
          autofocus: true,
          controller: controller,
          onSubmitted: (_) => submitDialog(),
        ),
        actions: [
          TextButton(
              onPressed: () {
                submitDialog();
              },
              child: const Text('SUBMIT'))
        ],
      ),
    );
  }

  void submitDialog() {
    Navigator.of(context).pop(controller.text);
    controller.clear();
  }

  // Widget showEventName(Event event) {
  //   return GestureDetector(
  //     onTap: () {
  //       openEventNameDialog(event);
  //     },
  //     child: Text(
  //       event.nameDist,
  //       style: TextStyle(
  //           fontSize:
  //               Theme.of(context).primaryTextTheme.bodyLarge?.fontSize ?? 16,
  //           color: Theme.of(context).colorScheme.primary),
  //     ),
  //   );
  // }

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
