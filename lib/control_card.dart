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
import 'package:ebrevet_card/controls_view_page.dart';
import 'package:ebrevet_card/mylogger.dart';
import 'package:ebrevet_card/outcome.dart';
import 'package:ebrevet_card/signature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import 'map_icon_button.dart';

import 'control.dart';
import 'time_till.dart';
import 'location.dart';
import 'app_settings.dart';
import 'activated_event.dart';
import 'control_state.dart';
import 'utility.dart';
import 'snackbarglobal.dart';
import 'checkin.dart';
import 'event.dart';
import 'my_activated_events.dart';

class ControlCard extends StatefulWidget {
  final Control control;
  final Event event;
  final ControlsViewStyle style;
  final ActivatedEvent? activeEvent;

  ControlCard(this.control, this.event,
      {this.style = ControlsViewStyle.live, super.key})
      : activeEvent = MyActivatedEvents.lookupMyActivatedEvent(event.eventID);

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
    var checkInTime = activeEvent?.controlCheckInTime(control);

    var isNotFinished = activeEvent == null ||
        widget.event.isIntermediateControl(control) ||
        !activeEvent.isFinished;

    var isDisqualified =
        activeEvent == null ? false : activeEvent.isDisqualified;

    final startIndex = widget.event.startControlKey;
    final finishIndex = widget.event.finishControlKey;
    final isStart = control.index == startIndex;
    final isFinish = control.index == finishIndex;

    var checkInSignatureString = activeEvent == null
        ? ""
        : ((isNotFinished)
            ? Signature.checkInCode(activeEvent, control).wordText
            : Signature.forCert(activeEvent).xyText);

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
                  if (!isStart && !isFinish)
                    TextSpan(
                        text: '${1 + control.index}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
                if (widget.style == ControlsViewStyle.live) ...[
                  Text(exactDistanceString(control.cLoc)),
                  Text(controlStatusString()),
                ],
                if (widget.style == ControlsViewStyle.future) ...[
                  // Text( "Control: ${1 + control.index} of ${widget.event.controls.length}"),
                  Text("Address: ${control.address}"),
                  Text("Style: ${control.style.name}"),
                  Text('Course distance: ${control.distMi.toString()} mi'),
                  // Text(exactDistanceString(control.cLoc)),
                  // Text("Location: ${control.lat} N;  ${control.long}E"),
                  // MapIconButton(latitude: control.lat, longitude: control.long),
                ],
                if (isDisqualified && widget.event.isFinishControl(control))
                  Text(
                    activeEvent.overallOutcomeDescription,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                if (checkInTime != null)
                  Text(isNotFinished
                      ? "Check-in Phrase: ($checkInSignatureString)"
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
    var open = activeEvent?.openActual(controlKey);
    var close = activeEvent?.closeActual(controlKey);
    if ((open ?? close) == null) return ""; // Pre ride undefined open/close
    if (widget.event.isUntimedControl(c)) {
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
    var checkInTime = activeEvent?.controlCheckInTime(control);

    Widget? checkInRow;

    if (checkInTime != null) {
      var checkInSignatureString = activeEvent?.makeCheckInSignature(control);

      var lastUpload = activeEvent?.outcomes.lastUpload;

      var checkInIcon = activeEvent == null
          ? const Icon(Icons.check_box_outline_blank_outlined,
              color: Colors.green)
          : ((lastUpload != null &&
                  (lastUpload.isAfter(checkInTime) ||
                      activeEvent.wasAutoChecked(control.index)))
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.pending_sharp, color: Colors.orangeAccent));
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
                "Control: ${1 + control.index} of ${widget.event.controls.length}"),
            Text("Address: ${control.address}"),
            Text("Style: ${control.style.name}"),
            Text('Course distance: ${control.distMi.toString()} mi'),
            Text(exactDistanceString(control.cLoc)),
            Text("Location: ${control.lat} N;  ${control.long}E"),
            Text(controlStatusString()),
            if (activeEvent != null)
              Text(
                  '${widget.event.isUntimedControl(control) ? 'Suggested ' : ''}Open Time: ${activeEvent.openActualString(control.index)}')
            else
              Text(
                  '${widget.event.isUntimedControl(control) ? 'Suggested ' : ''}Open Time: ${widget.event.openTimeString(control.index)}'),
            if (activeEvent != null)
              Text(
                  '${widget.event.isUntimedControl(control) ? 'Suggested ' : ''}Close Time: ${activeEvent.closeActualString(control.index)}')
            else
              Text(
                  '${widget.event.isUntimedControl(control) ? 'Suggested ' : ''}Close Time: ${widget.event.closeTimeString(control.index)}'),
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

  Widget? checkInButton() {
    final activeEvent = widget.activeEvent;
    final c = widget.control;
    final checkInTime = activeEvent?.controlCheckInTime(c);
    final lastUpload = activeEvent?.outcomes.lastUpload;

    // As a fix for situations when the route loops back to the same
    // control location and riders can be confused with multiple check-in buttons
    // this will make sure only one such button is ever available.

    if (activeEvent == null) return null;

    var firstAvailableIndex =
        activeEvent.firstAvailableUncheckedUnskippedControl();

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
    } else if (c.index != firstAvailableIndex) {
      return const Tooltip(
          message: 'Check into earlier open control first.',
          child: Icon(Icons.arrow_upward));
      // Otherwise, control is available. Gosh, let the cat check in.
    } else {
      return ElevatedButton(
          onPressed: () {
            if (AppSettings.allowCheckinComment.value ||
                activeEvent.wouldSkip(c)) {
              // Force dialog if skipping
              openCheckInDialog();
            } else {
              submitCheckIn(popAfter: false);
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('CHECK IN'),
              if (activeEvent.lateCheckIn)
                Text('LATE!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        )),
              if (activeEvent.wouldSkip(c))
                Text('SKIPPING!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        )),
            ],
          ));
    }
  }

  Future openCheckInDialog() {
    final control = widget.control;
    var activeEvent =
        widget.activeEvent!; // Only can be used with activated events
    var skipping = activeEvent.wouldSkip(control);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: skipping
            ? Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 64,
              )
            : const Icon(
                Icons.check_circle,
                size: 64,
              ),
        title: skipping
            ? Text(
                'Skipping Control',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            : const Text('Check In to Control'),
        content: checkInDialogContent(),
        actions: [
          if (skipping)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Just close the dialog
              },
              child: const Text("CANCEL"),
            ),
          TextButton(
              onPressed: () {
                submitCheckIn();
              },
              child: skipping
                  ? const Text('CHECK IN ANYWAY')
                  : const Text('CHECK IN NOW'))
        ],
      ),
    );
  }

  Widget checkInDialogContent() {
    final control = widget.control;
    var activeEvent =
        widget.activeEvent!; // Only can be used with activated events
    var isAvailable = activeEvent
        .isControlAvailable(control.index); // sets activeEvent.lateCheckIn

    var skipping = activeEvent.wouldSkip(control);
    var skipList = activeEvent.wouldBeSkippedControls(control).reversed;

    String skipListText = skipList
        .map((item) => "Control ${activeEvent.event.controls[item].index + 1}. "
            "${activeEvent.event.controls[item].name}")
        .join(", ");

    if (isAvailable == false) {
      return const Text('Control NOT Available');
    }
    if (skipping == true) {
      return Text(
          "WARNING: If you check into this control you would SKIP one or more previous controls: ($skipListText) "
          "ARE YOU SURE YOU WANT TO SKIP CONTROLS?");
    }
    return SingleChildScrollView(
      child: Column(
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
            decoration: const InputDecoration(hintText: 'Comment (optional)'),
            controller: controller,
            onSubmitted: (_) => submitCheckIn(),
          ),
        ],
      ),
    );
  }

  // This initiates the checkin with controlCheckIn() and then
  // presents some after-check-in nitices.

  void submitCheckIn({popAfter = true}) {
    var controlState = context.read<ControlState>();

    // this will do the actual check-in
    widget.activeEvent!
        .controlCheckIn(
      control: widget.control,
      comment: controller.text,
      controlState: controlState,
    )
        .then((result) {
      final activeEvent =
          widget.activeEvent!; // Only can be used on activated events
      final control = widget.control;
      final isDisqualified = activeEvent.isDisqualified;

      final isFinished = !(widget.event.isIntermediateControl(control) ||
          !activeEvent.isFinished);
      if ((result != null) || // Force dialog if anything interesting happened
          isFinished ||
          isDisqualified ||
          AppSettings.enablePostCheckinDialog.value) {
        openPostCheckInDialog(result);
      } else {
        postCheckInSnackBar(); // otherwise just give a snackbar notice.
      }

      // Attempt to download
      // the list of recent comments and put the new ones into the snackbar.

      if (AppSettings.notifyOtherRiderComments.value) {
        CommentFetcher.fetchAndFlush(activeEvent,
            excludeRiderID: AppSettings.rusaID.value,
            delay: const Duration(seconds: 5));
      }
    });
    controller.clear();
    // if submitCheckInDialog is called directly because
    // there was no checkin comment option, then the pop isn't needed.
    if (popAfter) Navigator.of(context).pop();
  }

  void postCheckInSnackBar() {
    final activeEvent = widget.activeEvent;
    final control = widget.control;
    // var checkInPhrase = Signature.checkInCode(activeEvent, control).wordText;

    final checkInDateTime =
        activeEvent!.outcomes.getControlCheckInTime(control.index);
    final checkInTimeString = Utility.toBriefDateTimeString(checkInDateTime);
    FlushbarGlobal.show(
        "Checked into Control ${control.index + 1} at $checkInTimeString");
  }

  Future openPostCheckInDialog(String? checkInResult) => showDialog(
        context: context,
        builder: (context) {
          final activeEvent = widget.activeEvent;
          final control = widget.control;
          final checkInDateTime =
              activeEvent!.outcomes.getControlCheckInTime(control.index);
          final checkInTimeString = Utility.toBriefTimeString(checkInDateTime);
          final textTheme = Theme.of(context).textTheme;
          final signatureStyle = textTheme.headlineMedium;
          final signatureColor = Theme.of(context).colorScheme.onError;
          final titleStyle = textTheme.headlineMedium;
          final smallPrint = textTheme.bodySmall;
          final largePrint = textTheme.bodyLarge;
          final overallOutcome = activeEvent.outcomes.overallOutcome;
          const spaceBox = SizedBox(
            height: 16,
          );
          const thinSpaceBox = SizedBox(
            height: 8,
          );

          final isDisqualified = activeEvent.isDisqualified;
          final isNotFinished = widget.event.isIntermediateControl(control) ||
              !activeEvent.isFinished;

          var checkInPhrase =
              Signature.checkInCode(activeEvent, control).wordText;

          var checkInSignatureString = isDisqualified
              ? 'RBA Review'
              : (isNotFinished
                  ? checkInPhrase
                  : Signature.forCert(activeEvent).xyText);

          MyLogger.entry("Control check-in: $checkInSignatureString");

          if (checkInResult != null) {
            return AlertDialog(
              icon: const Icon(Icons.error, size: 62.0),
              title: const Text("Check In FAILED"),
              content: Column(
                children: [
                  const Text("Something went wrong with your check-in:"),
                  thinSpaceBox,
                  Text(checkInResult,
                      style: largePrint, textAlign: TextAlign.center),
                  thinSpaceBox,
                  const Text(
                      "You can try checking in again. If this problem persists, use "
                      "your brevet card the old fashioned way. If you think this is an app "
                      "bug you should share the Activity Log to your RBA. You'll find that log "
                      "in app settings."),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Continue"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          } else {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
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
                          ? "RBA REVIEW NEEDED"
                          : ((isNotFinished)
                              ? 'Check-In Phrase'
                              : 'Finish Code'),
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
                          : (widget.event.isIntermediateControl(control)
                              ? "Ride On!"
                              : "RBA Review Needed"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('CONTINUE'))
              ],
            );
          }
        },
      );
}
