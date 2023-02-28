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

import 'package:ebrevet_card/files.dart';

import 'event.dart';
import 'outcome.dart';
// import 'current.dart';

// PastEvents are events with outcomes
// when a plain Event is "activated" it becomes
// a past event in the EventHistory map

class PastEvent {
  Event _event;
  EventOutcomes outcomes;

  PastEvent(this._event, this.outcomes);

  static Map<String, dynamic> toJson(PastEvent pe) => {
        'event': pe._event.toMap,
        'outcomes': pe.outcomes.toMap,
      };

  factory PastEvent.fromJsonMap(Map<String, dynamic> jsonMap) {
    var eventMap = jsonMap['event'];
    var outcomeMap = jsonMap['outcomes'];
    var e = Event.fromMap(eventMap);
    var o = EventOutcomes.fromMap(outcomeMap);
    return PastEvent(e, o);
  }

  Duration? get elapsedDuration {
    DateTime? startDateTime = (wasPreRide)
        ? outcomes.getControlCheckInTime(_event.startControlKey)
        : _event.startDateTime;
    DateTime? finishDateTime =
        outcomes.getControlCheckInTime(_event.finishControlKey);
    if (startDateTime == null || finishDateTime == null) return null;
    return finishDateTime.difference(startDateTime);
  }

  String get elapsedTimeString {
    if (elapsedDuration == null) return "No Finish";
    return "${elapsedDuration!.inHours}H ${elapsedDuration!.inMinutes % 60}M";
  }

  Event get event {
    return _event;
  }

  bool get wasPreRide => outcomes.wasPreRide;

  set overallOutcome(OverallOutcome o) {
    outcomes.overallOutcome = o;
  }

  // set outcomes(EventOutcomes outcomes) {
  //   _outcomes = outcomes;
  // }

  // EventOutcomes get outcomes {
  //   return _outcomes;
  // }

  String get overallOutcomeDescription {
    return outcomes.overallOutcome.description ??
        OverallOutcome.unknown.description;
  }
}


class EventHistory {

  static Map<String, PastEvent> _pastEventMap = {}; // Key is EventID string

  static const pastEventsFileName = 'past_events.json';

  // static clear() {
  //   _pastEventMap = {};  
  // }

  static Map<String, PastEvent> fromJsonMap(Map<String, dynamic> jsonMap) {
    var m = jsonMap
        .map((key, value) => MapEntry(key, PastEvent.fromJsonMap(value)));
    return m;
  }

  static Future<int> load() async {
    var storage = FileStorage(pastEventsFileName);
    try {
      print("** Loading event history from DISK");
      var pastEventsFromFile =
          await storage.readJSON(); //  as Map <String, PastEvent>;
      if (pastEventsFromFile.isNotEmpty) {
        _pastEventMap = fromJsonMap(pastEventsFromFile);
        print(
            "EventHistory.load() restored ${_pastEventMap.length} past activated events.");
        return _pastEventMap.length;
      } else {
        print("Empty, missing, or undecodable file: $pastEventsFileName");
        return 0;
      }
    } catch (e) {
      print("Couldn't fetch past events from file: $e");
      return 0;
    }
  }

  static save() {
    var storage = FileStorage(pastEventsFileName);
    try {
      storage.writeJSON(_pastEventMap);

      print("Saved  ${_pastEventMap.keys.length} events to file.");
    } catch (e) {
      print("Couldn't save past events to file.");
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

  static PastEvent add(Event e,
      {OverallOutcome? overallOutcome, bool? preRideMode}) {
    // }, Map<int, DateTime>? checkInTimeMap}) {
    if (_pastEventMap.containsKey(e.eventID)) {
      throw Exception(
          "Existing event ID ${e.eventID} in _pastEventMap. Can't add again.");
    } else {
      var o = EventOutcomes(
          oo: overallOutcome, preRideMode: preRideMode);
      // if (overallOutcome != null) o.overallOutcome = overallOutcome;
      // if (checkInTimeMap != null) o.checkInTimeMap = checkInTimeMap;
      var pe = PastEvent(e, o);
      _pastEventMap[e.eventID] = pe;

      return pe;
    }
  }
}
