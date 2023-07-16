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

import 'event.dart';
import 'outcome.dart';
import 'control.dart';
import 'app_settings.dart';
import 'snackbarglobal.dart';
import 'report.dart';
import 'control_state.dart';
import 'event_history.dart';
import 'signature.dart';

import 'mylogger.dart';

// ActivatedEvent s are events with outcomes
// when a plain Event is "activated" it becomes
// a past event in the EventHistory map

// TODO should probably be a child class of Event

class ActivatedEvent {
  String riderID;
  final Event _event;
  EventOutcomes outcomes;
  StartStyle startStyle;

  ActivatedEvent(this._event, this.riderID, this.outcomes, this.startStyle);

  Map<String, dynamic> toJson() => {
        'event': _event.toJson,
        'outcomes': outcomes.toJson(),
        'start_style': startStyle.name,
        'rider_id': riderID,
      };

  ActivatedEvent.fromJson(Map<String, dynamic> json)
      : riderID = json['rider_id'],
        startStyle = StartStyle.values.byName(json['start_style']),
        _event = Event.fromJson(json['event']),
        outcomes = EventOutcomes.fromJson(json['outcomes']);

  static int sort(ActivatedEvent a, ActivatedEvent b) =>
      Event.sort(a._event, b._event);

  // CONTROL CHECK IN -- one of the most important methods in the app!
  // CONTROL CHECK IN -- one of the most important methods in the app!
  // CONTROL CHECK IN -- one of the most important methods in the app!
  // CONTROL CHECK IN -- one of the most important methods in the app!

  void controlCheckIn({
    required Control control,
    String? comment,
    DateTime? checkInTime,
    ControlState? controlState,
  }) {
    var eventID = _event.eventID;

    assert(null != EventHistory.lookupPastEvent(eventID)); // Event in history
    assert(null == controlCheckInTime(control)); // shouldn't be set yet

    // for an auto-checkin of the first control, "now" is defined as the onTime for the event
    // passed in as a checkInTime parameter, otherwise now is now()
    var now = checkInTime?.toUtc() ?? DateTime.now().toUtc();

    // do the actual check-in
    outcomes.setControlCheckInTime(control.index, now);
    MyLogger.entry(
        "Checking into control ${control.index} at ${now.toString()}");

    // notify watchers
    if (controlState != null) {
      controlState.checkIn();
    }

    // Detect FINISH, or misordered controls at finish  (TODO Does this go here?)
    if (isFinishControl(control)) {
      if (isAllChecked && isAllCheckedInOrder()) {
        outcomes.overallOutcome = OverallOutcome.finish;
        SnackbarGlobal.show(
            'Congratulations! You have finished the ${_event.nameDist}. Your '
            'elapsed time: $elapsedTimeString');
      } else if (isAllChecked && !isAllCheckedInOrder()) {
        outcomes.overallOutcome = OverallOutcome.dnq;
        SnackbarGlobal.show('Controls checked in wrong order. DISQUALIFIED!');
      } else {
        outcomes.overallOutcome = OverallOutcome.dnq;
        SnackbarGlobal.show(
            'Failed to check into one or more intermediate controls. DISQUALIFIED!');
      }
    }

    assert(controlCheckInTime(control) != null); // should have just set this

    Report.constructReportAndSend(this, control: control, comment: comment,
        onUploadDone: () {
      if (controlState != null) controlState.reportUploaded();
    });
  }

  String makeCheckInSignature(Control ctrl) =>
      Signature.checkInCode(this, ctrl).xyText;

  bool get isFinished => (outcomes.overallOutcome == OverallOutcome.finish);
  bool get isDisqualified => (outcomes.overallOutcome == OverallOutcome.dnq);

  bool isIntermediateControl(control) =>
      control.index != event.finishControlKey;
  bool isFinishControl(control) => control.index == event.finishControlKey;

  bool get isFinalOutcomeFullyUploaded {
    var lastUpload = outcomes.lastUpload;
    var finishTime = outcomes.getControlCheckInTime(event.finishControlKey);
    return finishTime != null &&
        lastUpload != null &&
        lastUpload.isAfter(finishTime);
  }

  int? get lastCheckInControlKey {
    int k;
    for (k = event.startControlKey; k <= event.finishControlKey; k++) {
      if (outcomes.getControlCheckInTime(k) == null) {
        break;
      }
    }
    return k == event.startControlKey ? null : k - 1;
  }

  int get numberOfCheckIns {
    var last = lastCheckInControlKey;
    if (last == null) {
      return 0;
    } else {
      return 1 + last - event.startControlKey;
    }
  }

  int get numberOfControls =>
      1 + event.finishControlKey - event.startControlKey;

  bool get isCurrentOutcomeFullyUploaded {
    var lastUpload = outcomes.lastUpload;
    var k = lastCheckInControlKey;
    if (k == null) return true;
    var finishTime = outcomes.getControlCheckInTime(k);
    return finishTime != null &&
        lastUpload != null &&
        (lastUpload.isAfter(finishTime) || wasAutoChecked(k));
  }

  String get checkInFractionString {
    return (outcomes.overallOutcome == OverallOutcome.dns)
        ? ""
        : "Checked into $numberOfCheckIns/$numberOfControls controls";
  }

  bool get isAllChecked {
    for (var control in _event.controls) {
      if (false == controlIsChecked(control)) return false;
    }
    return true;
  }

  bool controlIsChecked(Control control) {
    return controlCheckInTime(control) != null;
  }

  DateTime? controlCheckInTime(Control control) {
    return outcomes.getControlCheckInTime(control.index);
  }

  bool wasAutoChecked(int key) {
    var checkInTime = outcomes.getControlCheckInTime(key);
    if (checkInTime == null) return false;
    if (key != event.startControlKey) return false;

    return event.startTimeWindow.onTime != null &&
        checkInTime.isAtSameMomentAs(event.startTimeWindow.onTime!);
  }

  bool isAllCheckedInOrder() {
    if (controlCheckInTime(_event.controls.first) == null) return false;
    DateTime tLast = controlCheckInTime(_event.controls.first)!;

    var nControls = _event.controls.length;
    for (var i = 1; i < nControls; i++) {
      // skip the first
      var control = _event.controls[i];
      var tControl = controlCheckInTime(control);
      if (tControl == null) return false;
      if (tControl.isBefore(tLast)) return false;
      tLast = tControl;
    }

    if (elapsedDuration == null) return false;

    return true;
  }

  String get isFullyUploadedString => (numberOfCheckIns == 0)
      ? 'Nothing to Upload'
      : (isCurrentOutcomeFullyUploaded
          ? 'Uploaded: ${outcomes.lastUploadString}'
          : 'Not Fully Uploaded');

  DateTime? get startDateTimeActual =>
      outcomes.getControlCheckInTime(_event.startControlKey);

  DateTime? get finishDateTimeActual =>
      outcomes.getControlCheckInTime(_event.finishControlKey);

  Duration? get elapsedDuration {
    var s = startDateTimeActual;
    var f = finishDateTimeActual;
    if ((s ?? f) == null) return null;
    return f!.difference(s!);
  }

  String get elapsedTimeString {
    if (elapsedDuration == null) return "No Finish";
    return "${elapsedDuration!.inHours}H ${elapsedDuration!.inMinutes % 60}M";
  }

  String get elapsedTimeStringhhmm {
    if (elapsedDuration == null) return "No Finish";
    return "${elapsedDuration!.inHours.toString().padLeft(2, '0')}"
        "${(elapsedDuration!.inMinutes % 60).toString().padLeft(2, '0')}";
  }

  String get elapsedTimeStringHHCMM {
    if (elapsedDuration == null) return "No Finish";
    return "${elapsedDuration!.inHours.toString().padLeft(2, '0')}:"
        "${(elapsedDuration!.inMinutes % 60).toString().padLeft(2, '0')}";
  }

  String get elapsedTimeStringVerbose {
    if (elapsedDuration == null) return "No Finish";
    return "${elapsedDuration!.inHours} hours, and  ${elapsedDuration!.inMinutes % 60} minutes";
  }

  DateTime? openActual(int controlKey) {
    Control control = _event.controls[controlKey];
    var openDur = control.openDuration(_event.controls.first.open);
    return startDateTimeActual?.add(openDur);
  }

  DateTime? closeActual(int controlKey) {
    Control control = _event.controls[controlKey];
    var closeDur = control.closeDuration(_event.controls.first.open);
    return startDateTimeActual?.add(closeDur);
  }

  String openActualString(int controlKey) =>
      openActual(controlKey)?.toLocal().toString().substring(0, 16) ?? '';
  String closeActualString(int controlKey) =>
      closeActual(controlKey)?.toLocal().toString().substring(0, 16) ?? '';

  bool isControlOpen(int controlKey) {
    // can start perm / preride any time
    if ((startStyle == StartStyle.preRide ||
            startStyle == StartStyle.permanent) &&
        controlKey == _event.startControlKey) return true;

    // no controls are open till the first one is checked
    if (startDateTimeActual == null) return false;

    Control control = _event.controls[controlKey];

    // untimed controls are always open
    if (control.style.isUntimed) return true;

    // otherwise, calulate open/close and compare
    var openDur = control.openDuration(_event.controls.first.open);
    var closeDur = control.closeDuration(_event.controls.first.open);
    var openActual = startDateTimeActual!.add(openDur);
    var closeActual = startDateTimeActual!.add(closeDur);

    var now = DateTime.now();

    return (openActual.isBefore(now) && closeActual.isAfter(now));
  }

  bool isControlNearby(int controlKey) =>
      _event.controls[controlKey].cLoc.isNearby;

  bool isControlAvailable(int controlKey) =>
      (isControlOpen(controlKey) || AppSettings.openTimeOverride.value) &&
      (isControlNearby(controlKey) ||
          AppSettings.controlProximityOverride.value);

  Event get event {
    return _event;
  }

  set overallOutcome(OverallOutcome o) {
    outcomes.overallOutcome = o;
  }

  String get overallOutcomeDescription {
    return outcomes.overallOutcome.description ??
        OverallOutcome.unknown.description;
  }
}