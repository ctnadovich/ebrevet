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

import 'package:ebrevet_card/files.dart';

import 'event.dart';
import 'outcome.dart';
import 'control.dart';
import 'app_settings.dart';
import 'current.dart';
import 'mylogger.dart';

// PastEvents are events with outcomes
// when a plain Event is "activated" it becomes
// a past event in the EventHistory map

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
      (AppSettings.openTimeOverride || isOpenControl(controlKey)) &&
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

class EventHistory {
  static Map<String, PastEvent> _pastEventMap = {}; // Key is EventID string

  static const pastEventsFileName = 'past_events.json';

  static PastEvent addActivate(Event e, String r, bool isPreride) {
    var pe = lookupPastEvent(e.eventID);
    if (pe != null) {
      pe.outcomes.overallOutcome = OverallOutcome.active;
    } else {
      pe = _add(e, r,
          overallOutcome: OverallOutcome.active, isPreride: isPreride);
      // need to save EventHistory now
    }

    save();

    // It seems excessive to save the whole event history
    // every activation, but this certainly does the job.
    // The only time an event can change state is when
    // activated or at a control checkin.

    // once an event is "activated" it gets copied to past events map and becomes immutable -- only the outcome can change
    // so conceivably the preriders could have a different "event" saved than the day-of riders

    return pe;
  }

  static Map<String, PastEvent> fromJsonMap(Map<String, dynamic> jsonMap) {
    var m = jsonMap
        .map((key, value) => MapEntry(key, PastEvent.fromJsonMap(value)));
    return m;
  }

  static Future<int> load() async {
    var storage = FileStorage(pastEventsFileName);
    try {
      MyLogger.entry("** Loading event history from DISK");
      var pastEventsFromFile =
          await storage.readJSON(); //  as Map <String, PastEvent>;
      if (pastEventsFromFile.isNotEmpty) {
        _pastEventMap = fromJsonMap(pastEventsFromFile);
        MyLogger.entry(
            "EventHistory.load() restored ${_pastEventMap.length} past activated events.");
        return _pastEventMap.length;
      } else {
        MyLogger.entry(
            "Empty, missing, or undecodable file: $pastEventsFileName");
        return 0;
      }
    } catch (e) {
      MyLogger.entry("Couldn't fetch past events from file: $e");
      return 0;
    }
  }

  static save() {
    var storage = FileStorage(pastEventsFileName);
    try {
      storage.writeJSON(_pastEventMap);

      MyLogger.entry("Saved  ${_pastEventMap.keys.length} events to file.");
    } catch (e) {
      MyLogger.entry("Couldn't save past events to file.");
    }
  }

  static PastEvent? lookupPastEvent(String eventID) {
    return _pastEventMap[eventID];
  }

  static EventOutcomes? getFullOutcomes(String eventID) {
    return lookupPastEvent(eventID)?.outcomes;
  }

  static String? getElapsedTimeString(String eventID) {
    return lookupPastEvent(eventID)?.elapsedTimeString;
  }

  static String getOverallOutcomeDescription(String eventID) {
    return lookupPastEvent(eventID)?.overallOutcomeDescription ??
        OverallOutcome.unknown.description;
  }

  static OverallOutcome? getOverallOutcome(String eventID) {
    return getFullOutcomes(eventID)?.overallOutcome;
  }

  // static Map<int, DateTime>? getCheckInTimeMap(String eventID) {
  //   return getFullOutcomes(eventID)?.checkInTimeMap;
  // }

  static bool isInHistory(String eventID) {
    return _pastEventMap.containsKey(eventID);
  }

  static List<PastEvent> get pastEventList {
    var eventList = _pastEventMap.values.toList();
    eventList.sort((a, b) =>
        a.event.startDateTime.isAfter(b.event.startDateTime)
            ? -1
            : (a.event.startDateTime.isBefore(b.event.startDateTime) ? 1 : 0));
    return eventList;
  }

  // When using this, don't forget to call EventHistory.save() afterwards

  static PastEvent _add(Event e, String r,
      {OverallOutcome? overallOutcome, bool? isPreride}) {
    // }, Map<int, DateTime>? checkInTimeMap}) {
    if (_pastEventMap.containsKey(e.eventID)) {
      throw StateError(
          "Existing event ID ${e.eventID} in _pastEventMap. Can't add again.");
    } else {
      var o =
          EventOutcomes(overallOutcome: overallOutcome, isPreride: isPreride);
      var pe = PastEvent(e, r, o, isPreride ?? false);
      _pastEventMap[e.eventID] = pe;

      return pe;
    }
  }

  static deletePastEvent(PastEvent pe) {
    if (_pastEventMap.containsKey(pe._event.eventID)) {
      if (Current.activatedEvent?._event.eventID == pe._event.eventID) {
        Current.deactivate();
      }
      _pastEventMap.remove(pe._event.eventID);
      save();
    }
  }
}
