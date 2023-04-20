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

// PastEvents are events with outcomes
// when a plain Event is "activated" it becomes
// a past event in the EventHistory map

// TODO should probably be a child class of Event

class PastEvent {
  String riderID;
  Event _event;
  EventOutcomes outcomes;
  bool isPreride;

  PastEvent(this._event, this.riderID, this.outcomes, this.isPreride);

  static Map<String, dynamic> toJson(PastEvent pe) => {
        'event': pe._event.toMap,
        'outcomes': pe.outcomes.toMap,
        'preride': pe.isPreride,
        'rider_id': pe.riderID,
      };

  factory PastEvent.fromJsonMap(Map<String, dynamic> jsonMap) {
    var eventMap = jsonMap['event'];
    var outcomeMap = jsonMap['outcomes'];
    var isPreride = jsonMap['preride'];
    var riderID = jsonMap['rider_id'];
    var e = Event.fromMap(eventMap);
    var o = EventOutcomes.fromMap(outcomeMap);
    return PastEvent(e, riderID, o, isPreride);
  }

  void controlCheckIn(
      {required Control control,
      String? comment,
      // Function? onUploadDone,
      ControlState? controlState}) {
    assert(AppSettings.autoFirstControlCheckIn ||
        isAvailable(
            control.index)); // Trying to check into an unavailable control
    var eventID = _event.eventID;
    assert(null != EventHistory.lookupPastEvent(eventID));
    // Trying to check into a never activated event

    var now = DateTime.now().toUtc();
    outcomes.setControlCheckInTime(control.index, now);
    if (controlState != null) controlState.checkIn();
    if (isAllChecked) {
      if (isAllCheckedInOrder()) {
        outcomes.overallOutcome = OverallOutcome.finish;
        // Current.deactivate();
        SnackbarGlobal.show(
            'Congratulations! You have finished the ${_event.nameDist}. Your '
            'elapsed time: $elapsedTimeString');
      } else {
        outcomes.overallOutcome = OverallOutcome.dnq;
        // Current.deactivate();
        SnackbarGlobal.show('Controls checked in wrong order. Disqualified!');
      }
    }

    assert(controlCheckInTime(control) != null); // should have just set this

    Report.constructReportAndSend(this, control: control, comment: comment,
        onUploadDone: () {
      if (controlState != null) controlState.reportUploaded();
    });

    // return outcomes.overallOutcome;
  }

  String makeCheckInSignature(Control ctrl) {
    var checkInSignatureString = '';
    var checkInTime = controlCheckInTime(ctrl);
    if (checkInTime != null) {
      var checkInTimeString = checkInTime.toUtc().toString().substring(0, 16);
      var checkInData = "C${ctrl.index} $checkInTimeString";
      var checkInSignature = Signature(
          data: checkInData, event: event, riderID: riderID, codeLength: 4);
      checkInSignatureString =
          Signature.substituteZeroOneXY(checkInSignature.text);
      MyLogger.entry("checkInData: $checkInData; "
          "checkInSignature: $checkInSignatureString");
    }
    return checkInSignatureString;
  }

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
        lastUpload.isAfter(finishTime);
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

  bool isAllCheckedInOrder() {
    if (controlCheckInTime(_event.controls.first) == null) return false;
    DateTime tLast = isPreride
        ? controlCheckInTime(_event.controls.first)!
        : _event.startDateTime;
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

  DateTime? get startDateTimeActual => (isPreride)
      ? outcomes.getControlCheckInTime(_event.startControlKey)
      : _event.startDateTime;

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

  String get elapsedTimeStringVerbose {
    if (elapsedDuration == null) return "No Finish";
    return "${elapsedDuration!.inHours} hours, and  ${elapsedDuration!.inMinutes % 60} minutes";
  }

  DateTime? openActual(int controlKey) {
    Control control = _event.controls[controlKey];
    var openDur = control.openDuration(_event.startDateTime);
    return startDateTimeActual?.add(openDur);
  }

  DateTime? closeActual(int controlKey) {
    Control control = _event.controls[controlKey];
    var closeDur = control.closeDuration(_event.startDateTime);
    return startDateTimeActual?.add(closeDur);
  }

  String openActualString(int controlKey) =>
      openActual(controlKey)?.toLocal().toString().substring(0, 16) ?? '';
  String closeActualString(int controlKey) =>
      closeActual(controlKey)?.toLocal().toString().substring(0, 16) ?? '';

  bool isOpenControl(int controlKey) {
    // can start preride any time
    if (isPreride && controlKey == _event.startControlKey) return true;

    // no controls are open till the first one is checked
    if (startDateTimeActual == null) return false;

    Control control = _event.controls[controlKey];

    var openDur = control.openDuration(_event.startDateTime);
    var closeDur = control.closeDuration(_event.startDateTime);
    var openActual = startDateTimeActual!.add(openDur);
    var closeActual = startDateTimeActual!.add(closeDur);

    var now = DateTime.now();

    return (openActual.isBefore(now) && closeActual.isAfter(now));
  }

  bool isNear(int controlKey) => _event.controls[controlKey].cLoc.isNearControl;

  bool isAvailable(int controlKey) =>
      (AppSettings.openTimeOverride.value || isOpenControl(controlKey)) &&
      isNear(controlKey);

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
