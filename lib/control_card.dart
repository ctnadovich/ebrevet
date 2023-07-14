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
import 'past_event.dart';
import 'control_state.dart';
import 'utility.dart';

class ControlCard extends StatefulWidget {
  final Control control;
  final PastEvent pastEvent;

  const ControlCard(this.control, this.pastEvent, {super.key});

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
    var activeEvent = widget.pastEvent;
    var control = widget.control;
    var checkInTime = activeEvent.controlCheckInTime(control);
    var isNotFinished =
        activeEvent.isIntermediateControl(control) || !activeEvent.isFinished;

    var startIndex = activeEvent.event.startControlKey;
    var finishIndex = activeEvent.event.finishControlKey;

    var checkInSignatureString = (isNotFinished)
        ? Signature.checkInCode(activeEvent, control).xyText
        : Signature.forCert(activeEvent).xyText;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon((control.index == startIndex)
                ? Icons.play_arrow
                : ((control.index == finishIndex)
                    ? Icons.stop
                    : Icons.checklist)),
            title: showControlName(),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exactDistanceString(control.cLoc)),
                Text(controlStatusString()),
                (checkInTime != null)
                    ? Text(isNotFinished
                        ? "Check-in Code: ($checkInSignatureString)"
                        : "Finish Code: ($checkInSignatureString)")
                    : const SizedBox.shrink(),
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
    var activeEvent = widget.pastEvent;
    var open = activeEvent.openActual(controlKey);
    var close = activeEvent.closeActual(controlKey);
    if ((open ?? close) == null) return ""; // Pre ride undefined open/close
    if (c.style.isUntimed) return "Open (untimed)";
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

  Widget showControlName() {
    var control = widget.control;
    return GestureDetector(
      onTap: () {
        openControlNameDialog();
      },
      child: Text(
        control.name,
        style: TextStyle(
            fontSize:
                Theme.of(context).primaryTextTheme.bodyLarge?.fontSize ?? 16,
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Future openControlNameDialog() {
    var activeEvent = widget.pastEvent;
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
            Text("Style: ${control.style}"),
            Text('Course distance: ${control.distMi.toString()} mi'),
            Text(exactDistanceString(control.cLoc)),
            Text("Location: ${control.lat} N;  ${control.long}E"),
            Text(controlStatusString()),
            if (!control.style.isUntimed)
              Text('Open Time: ${activeEvent.openActualString(control.index)}'),
            if (!control.style.isUntimed)
              Text(
                  'Close Time: ${activeEvent.closeActualString(control.index)}'),
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

  Widget checkInButton() {
    final activeEvent = widget.pastEvent;
    final c = widget.control;
    final checkInTime = activeEvent.controlCheckInTime(c);
    final lastUpload = activeEvent.outcomes.lastUpload;

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
        ],
      );
    } else if (false == activeEvent.isControlAvailable(c.index)) {
      var open = activeEvent.isControlOpen(c.index);
      var near = activeEvent.isControlNearby(c.index);
      var openTimeOverride = AppSettings.openTimeOverride;
      var proximityOverride = AppSettings.controlProximityOverride.value;

      return Text.rich(
          TextSpan(style: const TextStyle(fontSize: 12), children: [
        if (open || openTimeOverride.value)
          TextSpan(
            text: 'Open now${openTimeOverride.value ? "*" : ""}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        if (!open && !openTimeOverride.value)
          const TextSpan(
            text: 'Not open',
          ),
        const TextSpan(text: ' - '),
        if (near)
          TextSpan(
            text: 'At control${proximityOverride ? "*" : ""}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        if (!near && RiderLocation.riderLocation != null)
          const TextSpan(
            text: 'Not near',
          ),
        if (RiderLocation.riderLocation == null)
          const TextSpan(
            text: 'Dist ??',
          ),
      ]));
    } else {
      return ElevatedButton(
        onPressed: () {
          openCheckInDialog();
        },
        child: const Text('CHECK IN'),
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

  Column checkInDialogContent() {
    final control = widget.control;
    return Column(
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
        TextField(
          decoration: const InputDecoration(hintText: 'Comment (optional)'),
          controller: controller,
          onSubmitted: (_) => submitCheckInDialog(),
        ),
      ],
    );
  }

  void submitCheckInDialog() {
    var controlState = context.read<ControlState>();
    widget.pastEvent.controlCheckIn(
      control: widget.control,
      comment: controller.text,
      controlState: controlState,
    );
    controller.clear();
    Navigator.of(context).pop();

    openPostCheckInDialog();
  }

  Future openPostCheckInDialog() => showDialog(
        context: context,
        builder: (context) {
          final activeEvent = widget.pastEvent;
          final control = widget.control;
          final checkInDateTime =
              activeEvent.outcomes.getControlCheckInTime(control.index);
          final checkInTimeString = Utility.toBriefTimeString(checkInDateTime);
          var textTheme = Theme.of(context).textTheme;
          var signatureStyle = textTheme.headlineLarge;
          var signatureColor = Theme.of(context).colorScheme.onError;
          var titleStyle = textTheme.headlineMedium;
          var smallPrint = textTheme.bodySmall;
          var overallOutcome = activeEvent.outcomes.overallOutcome;
          const spaceBox = SizedBox(
            height: 16,
          );
          const thinSpaceBox = SizedBox(
            height: 8,
          );

          var isNotFinished = activeEvent.isIntermediateControl(control) ||
              !activeEvent.isFinished;

          var checkInSignature = (isNotFinished)
              ? Signature.checkInCode(activeEvent, control)
              : Signature.forCert(activeEvent);
          var checkInSignatureString = checkInSignature.xyText;
          var checkInPlaintext = checkInSignature.plainText;

          MyLogger.entry("Control check-in: $checkInPlaintext");

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
                  (isNotFinished) ? 'Control Check-In Code' : 'Finish Code',
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
                Text(
                  'Write on Brevet Card',
                  style: smallPrint,
                ),
                Text(
                  'as EPP backup!',
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
