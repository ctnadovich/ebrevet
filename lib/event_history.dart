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
import 'mylogger.dart';
import 'activated_event.dart';
import 'app_settings.dart';
import 'control_state.dart';

class EventHistory {
  static Map<String, ActivatedEvent> _pastEventMap =
      {}; // Key is EventID string

  // START AN EVENT -- this method turns a mere event, into an activated
  // PastEvent.   The name PastEvent is misleading since it also could
  // be a "current event" that we are riding now. The main difference
  // is that PastEvents have outcomes, like control check ins, and
  // mere Events do not have outcomes.   Probably PastEvent should
  // be refactored as a child object of Event.

  static ActivatedEvent addActivate(Event e,
      {String? riderID, StartStyle? startStyle, ControlState? controlState}) {
    var pe = lookupPastEvent(e.eventID);
    if (pe != null) {
      pe.outcomes.overallOutcome = OverallOutcome.active; // reactivate
    } else {
      // otherwise add

      if (riderID == null) {
        throw Exception("Can't activate event. No rider specified.");
      }
      if (startStyle == null) {
        throw Exception("Can't activate event. No start style specified.");
      }
      pe = _add(
        e,
        riderID,
        startStyle,
        overallOutcome: OverallOutcome.active,
      );
    }

    return pe;
  }

  static Map<String, ActivatedEvent> fromJsonMap(Map<String, dynamic> jsonMap) {
    var m = jsonMap
        .map((key, value) => MapEntry(key, ActivatedEvent.fromJson(value)));
    return m;
  }

  static Future<int> load() async {
    var storage = FileStorage(AppSettings.pastEventsFileName);
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
            "Empty, missing, or undecodable file: ${storage.fileName}");
        return 0;
      }
    } catch (e) {
      MyLogger.entry("Couldn't fetch past events from file: $e");
      return 0;
    }
  }

  static save() {
    var storage = FileStorage(AppSettings.pastEventsFileName);
    try {
      storage.writeJSON(_pastEventMap);

      MyLogger.entry("Saved  ${_pastEventMap.keys.length} events to file.");
    } catch (e) {
      MyLogger.entry("Couldn't save past events to file.");
    }
  }

  static ActivatedEvent? lookupPastEvent(String eventID) {
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

  static bool isInHistory(String eventID) {
    return _pastEventMap.containsKey(eventID);
  }

  static List<ActivatedEvent> get pastEventList {
    var eventList = _pastEventMap.values.toList();
    eventList.sort(ActivatedEvent.sort);
    return eventList;
  }

  // When using this, don't forget to call EventHistory.save() afterwards

  static ActivatedEvent _add(
    Event e,
    String riderID,
    StartStyle startStyle, {
    OverallOutcome? overallOutcome,
  }) {
    // }, Map<int, DateTime>? checkInTimeMap}) {
    if (_pastEventMap.containsKey(e.eventID)) {
      throw StateError(
          "Existing event ID ${e.eventID} in _pastEventMap. Can't add again.");
    } else {
      var o = EventOutcomes(overallOutcome: overallOutcome);
      var pe = ActivatedEvent(e, riderID, o, startStyle);
      _pastEventMap[e.eventID] = pe;

      return pe;
    }
  }

  static deletePastEvent(ActivatedEvent pe) {
    if (_pastEventMap.containsKey(pe.event.eventID)) {
      _pastEventMap.remove(pe.event.eventID);
      save();
    }
  }
}
