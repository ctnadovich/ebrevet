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

import 'dart:async';
import 'package:ebrevet_card/mylogger.dart';
import 'package:ebrevet_card/outcome.dart';
import 'package:ebrevet_card/signature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'control.dart';
import 'time_till.dart';
import 'location.dart';
import 'app_settings.dart';
import 'activated_event.dart';
import 'control_state.dart';
import 'utility.dart';

class ControlCard extends StatefulWidget {
  final Control control;
  final ActivatedEvent activeEvent;

  const ControlCard(this.control, this.activeEvent, {super.key});

  @override
  State<ControlCard> createState() => _ControlCardState();
}

class _ControlCardState extends State<ControlCard> {
  late TextEditingController controller;

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
    var activeEvent = widget.activeEvent;
    var control = widget.control;
    var checkInTime = activeEvent.controlCheckInTime(control);

    var isNotFinished =
        activeEvent.isIntermediateControl(control) || !activeEvent.isFinished;

    var isDisqualified = activeEvent.isDisqualified;

    final startIndex = activeEvent.event.startControlKey;
    final finishIndex = activeEvent.event.finishControlKey;
    final isStart = control.index == startIndex;
    final isFinish = control.index == finishIndex;

    var checkInSignatureString = (isNotFinished)
        ? Signature.checkInCode(activeEvent, control).wordText
        : Signature.forCert(activeEvent).xyText;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: IconButton(
              onPressed: () {
                openControlInfoDialog();
              },
              icon: const Icon(Icons.info_outline),
            ),
            title: Text.rich(
              TextSpan(
                children: [
                  // if (isStart) const WidgetSpan(child: Icon(Icons.play_arrow)),
                  // if (isFinish) const WidgetSpan(child: Icon(Icons.stop)),
                  if (isStart)
                    const TextSpan(
                        text: 'Start: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  if (isFinish)
                    const TextSpan(
                        text: 'Finish: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                    text: control.name,
                    style: TextStyle(
                      fontSize: Theme.of(context)
                              .primaryTextTheme
                              .bodyLarge
                              ?.fontSize ??
                          16,
                      // color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exactDistanceString(control.cLoc)),
                Text(controlStatusString()),
                if (isDisqualified && activeEvent.isFinishControl(control))
                  Text(
                    activeEvent.overallOutcomeDescription,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                if (checkInTime != null)
                  Text(isNotFinished
                      ? (isDisqualified && isFinish
                          ? "DNQ Check In: ($checkInSignatureString)"
                          : "Check-in Phrase: ($checkInSignatureString)")
                      : "Finish Code: ($checkInSignatureString)"),
              ],
            ),
            trailing: checkInButton(),
          ),
          const SizedBox(
            height: 5,
          )
        ],
      ),
    );
  }

  String controlStatusString() {
    DateTime now = DateTime.now();
    var c = widget.control;
    int controlKey = c.index;
    var activeEvent = widget.activeEvent;
    var open = activeEvent.openActual(controlKey);
    var close = activeEvent.closeActual(controlKey);
    if ((open ?? close) == null) return ""; // Pre ride undefined open/close
    if (activeEvent.isUntimedControl(c)) {
      return "Open (untimed)";
    }
    if (open!.isAfter(now)) {
      // Open in future
      var tt = TimeTill(open);
      return "Opens ${tt.terseDateTime} (in ${tt.interval} ${tt.unit})";
    } else if (close!.isBefore(now)) {
      // Closed in past
      var tt = TimeTill(close);
      return "Closed ${tt.terseDateTime} (${tt.interval} ${tt.unit} ago)";
    } else {
      var tt = TimeTill(close);
      //var ct = c.close.toLocal().toString().substring(11, 16);
      return "Closes in ${tt.interval} ${tt.unit}";
    }
  }

  String exactDistanceString(ControlLocation cLoc) {
    return ('Dir: ${cLoc.crowDistString} ${cLoc.crowCompassHeadingString}');
  }

  // Widget showControlName() {
  //   var control = widget.control;
  //   return GestureDetector(
  //     onTap: () {
  //       openControlInfoDialog();
  //     },
  //     child: Text(
  //       control.name,
  //       style: TextStyle(
  //           fontSize:
  //               Theme.of(context).primaryTextTheme.bodyLarge?.fontSize ?? 16,
  //           color: Theme.of(context).colorScheme.primary),
  //     ),
  //   );
  // }

  Future openControlInfoDialog() {
    var activeEvent = widget.activeEvent;
    var control = widget.control;
    var checkInTime = activeEvent.controlCheckInTime(control);

    Widget? checkInRow;

    if (checkInTime != null) {
      var checkInSignatureString = activeEvent.makeCheckInSignature(control);

      var lastUpload = activeEvent.outcomes.lastUpload;

      var checkInIcon = (lastUpload != null &&
              (lastUpload.isAfter(checkInTime) ||
                  activeEvent.wasAutoChecked(control.index)))
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.pending_sharp, color: Colors.orangeAccent);
      checkInRow = Row(
        children: [
          const Text('Check In: '),
          checkInIcon,
          Text(
              " ${Utility.toBriefTimeString(checkInTime)} ($checkInSignatureString)"),
        ],
      );
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(control.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Control: ${1 + control.index} of ${activeEvent.event.controls.length}"),
            Text("Address: ${control.address}"),
            Text("Style: ${control.style.name}"),
            Text('Course distance: ${control.distMi.toString()} mi'),
            Text(exactDistanceString(control.cLoc)),
            Text("Location: ${control.lat} N;  ${control.long}E"),
            Text(controlStatusString()),
            Text(
                '${activeEvent.isUntimedControl(control) ? 'Suggested ' : ''}Open Time: ${activeEvent.openActualString(control.index)}'),
            Text(
                '${activeEvent.isUntimedControl(control) ? 'Suggested ' : ''}Close Time: ${activeEvent.closeActualString(control.index)}'),
            checkInRow ?? const Text('Not checked in.'),
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

  // Decide what sort of check in button, if any, should be displayed.
  // This is also the "gateway" to checkin, deciding if the rider
  // should be allowed to check in.

  Widget checkInButton() {
    final activeEvent = widget.activeEvent;
    final c = widget.control;
    final checkInTime = activeEvent.controlCheckInTime(c);
    final lastUpload = activeEvent.outcomes.lastUpload;

    // Can't check in -- you skipped me
    if (activeEvent.wasSkipped(c)) {
      return Text('SKIPPED!',
          style: TextStyle(
            fontSize:
                Theme.of(context).primaryTextTheme.bodyLarge?.fontSize ?? 16,
          ));
    }

    // Can't check in -- already did (show time, green/orange check etc..)
    if (checkInTime != null) {
      var checkInIcon = (lastUpload != null &&
              (lastUpload.isAfter(checkInTime) ||
                  activeEvent.wasAutoChecked(c.index)))
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.pending_sharp, color: Colors.orangeAccent);
      return Column(
        children: [
          checkInIcon,
          Text(Utility.toBriefTimeString(checkInTime)),
          if (activeEvent.checkedInLate(c)) const Text('LATE!')
        ],
      );

      // Control NOT available, figure out why and show
    } else if (false == activeEvent.isControlAvailable(c.index)) {
      // || activeEvent.previousControlsAreAvailable(c.index)) {
      var open = activeEvent.isControlOpen(c.index);
      var near = activeEvent.isControlNearby(c.index);
      var openTimeOverride = AppSettings.openTimeOverride;
      var proximityOverride = AppSettings.controlProximityOverride.value;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (open || openTimeOverride.value)
            Text(
              'Open now${openTimeOverride.value ? "*" : ""}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (!open && !openTimeOverride.value)
            const Text(
              'Not open',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          if (near)
            Text(
              'At control${proximityOverride ? "*" : ""}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (!near && RiderLocation.riderLocation != null)
            const Text(
              'Not near',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          if (RiderLocation.riderLocation == null)
            const Text(
              'Dist ??',
            ),
        ],
      );

      // Otherwise, control is available. Gosh, let the cat check in.
    } else {
      return ElevatedButton(
        onPressed: () {
          if (AppSettings.allowCheckinComment.value) {
            openCheckInDialog();
          } else {
            submitCheckInDialog();
          }
        },
        child: activeEvent.lateCheckIn
            ? const Column(
                children: [Text('CHECK IN'), Text('LATE!')],
              )
            : const Text('CHECK IN'),
      );
    }
  }

  Future openCheckInDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            size: 64,
          ),
          title: const Text('Check In to Control'),
          content: checkInDialogContent(),
          actions: [
            TextButton(
                onPressed: () {
                  submitCheckInDialog();
                },
                child: const Text('CHECK IN NOW'))
          ],
        ),
      );

  Widget checkInDialogContent() {
    final control = widget.control;
    var activeEvent = widget.activeEvent;
    var isAvailable = activeEvent
        .isControlAvailable(control.index); // sets activeEvent.lateCheckIn

    return isAvailable == false
        ? const Text('Control NOT Available')
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                control.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(controlStatusString()),
              Text(exactDistanceString(control.cLoc)),
              if (control.cLoc.isNearby)
                const Text(
                  'AT THIS CONTROL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (activeEvent.lateCheckIn)
                Text('THIS IS A LATE CHECK IN!',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(fontWeight: FontWeight.bold)),
              TextField(
                decoration:
                    const InputDecoration(hintText: 'Comment (optional)'),
                controller: controller,
                onSubmitted: (_) => submitCheckInDialog(),
              ),
            ],
          );
  }

  void submitCheckInDialog() {
    var controlState = context.read<ControlState>();

    // this will do the actual check-in
    widget.activeEvent.controlCheckIn(
      control: widget.control,
      comment: controller.text,
      controlState: controlState,
    );
    controller.clear();
    // if submitCheckInDialog is called directly because
    // there was no checkin comment option, then the pop isn't needed.
    if (AppSettings.allowCheckinComment.value) Navigator.of(context).pop();

    openPostCheckInDialog();
  }

  Future openPostCheckInDialog() => showDialog(
        context: context,
        builder: (context) {
          final activeEvent = widget.activeEvent;
          final control = widget.control;
          final checkInDateTime =
              activeEvent.outcomes.getControlCheckInTime(control.index);
          final checkInTimeString = Utility.toBriefTimeString(checkInDateTime);
          final textTheme = Theme.of(context).textTheme;
          final signatureStyle = textTheme.headlineLarge;
          final signatureColor = Theme.of(context).colorScheme.onError;
          final titleStyle = textTheme.headlineMedium;
          final smallPrint = textTheme.bodySmall;
          final overallOutcome = activeEvent.outcomes.overallOutcome;
          const spaceBox = SizedBox(
            height: 16,
          );
          const thinSpaceBox = SizedBox(
            height: 8,
          );

          final isDisqualified = activeEvent.isDisqualified;
          final isNotFinished = activeEvent.isIntermediateControl(control) ||
              !activeEvent.isFinished;

          var checkInPhrase =
              Signature.checkInCode(activeEvent, control).wordText;

          var checkInSignatureString = isDisqualified
              ? 'DNQ!'
              : (isNotFinished
                  ? checkInPhrase
                  : Signature.forCert(activeEvent).xyText);

          // var checkInPlaintext = checkInSignature?.plainText ?? "Disqualified!";

          MyLogger.entry("Control check-in: $checkInSignatureString");

          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (isNotFinished) ? 'Check In Recorded' : 'Ride Completed',
                  style: titleStyle,
                ),
                Text(
                  "At $checkInTimeString",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                spaceBox,
                Text(
                  isDisqualified
                      ? "Disqualified"
                      : ((isNotFinished) ? 'Check-In Phrase' : 'Finish Code'),
                ),
                thinSpaceBox,
                Container(
                  color: signatureColor,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    checkInSignatureString,
                    style: signatureStyle,
                  ),
                ),
                spaceBox,
                if (isDisqualified)
                  Text(
                    'Last Control Check-in Phrase:',
                    style: smallPrint,
                  ),
                if (isDisqualified)
                  Text(
                    checkInPhrase,
                    style: smallPrint,
                  ),
                if (!isDisqualified && isNotFinished)
                  Text(
                    'OPTIONAL: Write Phrase and Time',
                    style: smallPrint,
                  ),
                if (!isDisqualified && isNotFinished)
                  Text(
                    'on Brevet Card as backup!',
                    style: smallPrint,
                  ),
                if (!isDisqualified && !isNotFinished)
                  Text(
                    'Record Finish Code as Proof',
                    style: smallPrint,
                  ),
                spaceBox,
                Text(activeEvent.checkInFractionString),
                Text(
                  (overallOutcome == OverallOutcome.finish)
                      ? "Congratulations! You have finished the ${activeEvent.event.nameDist} in ${activeEvent.elapsedTimeString}."
                      : (activeEvent.isIntermediateControl(control)
                          ? "Ride On!"
                          : "Disqualified (See the RBA)"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CONTINUE'))
            ],
          );
        },
      );
}
