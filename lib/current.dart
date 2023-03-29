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

import 'snackbarglobal.dart';
import 'event.dart';
import 'outcome.dart';
import 'control.dart';
import 'event_history.dart';
import 'mylogger.dart';
import 'report.dart';

// Class for doing stuff with the the current context of event/rider/region
// The Event class has a static "current" that holds one of these during the ride

class Current {
  static PastEvent? activatedEvent;

  // The event we are riding NOW, stored in EventHistory

  static void activate(Event e, String riderID, {bool isPreride = false}) {
    activatedEvent = EventHistory.addActivate(e, riderID, isPreride);
    MyLogger.entry(
        "Activated ${activatedEvent!.event.nameDist}${isPreride ? ' PRERIDE' : ''}");
  }

  static void deactivate() => activatedEvent = null;

  static Event? get event {
    return activatedEvent?.event;
  }

  static EventOutcomes? get outcomes {
    return activatedEvent?.outcomes;
  }

  static bool get isActivated {
    return activatedEvent != null;
  }

  static bool get isAllChecked {
    if (event == null) return false;
    for (var control in event!.controls) {
      if (false == controlIsChecked(control)) return false;
    }
    return true;
  }

  static bool isAllCheckedInOrder() {
    if (activatedEvent == null) return false;
    if (controlCheckInTime(event!.controls.first) == null) return false;
    DateTime tLast = activatedEvent!.isPreride
        ? controlCheckInTime(event!.controls.first)!
        : event!.startDateTime;
    for (var control in event!.controls) {
      var tControl = controlCheckInTime(control);
      if (tControl == null) return false;
      if (tControl.isBefore(tLast)) return false;
      tLast = tControl;
    }

    if (activatedEvent!.elapsedDuration == null) return false;

    return true;
  }

  static void controlCheckIn({required Control control, String? comment}) {
    assert(activatedEvent != null); // Trying to check into an unavailable event
    assert(activatedEvent!.isAvailable(
        control.index)); // Trying to check into an unavailable control
    var eventID = activatedEvent!.event.eventID;
    assert(null != EventHistory.lookupPastEvent(eventID));
    // Trying to check into a never activated event

    var now = DateTime.now().toUtc();
    activatedEvent!.outcomes.setControlCheckInTime(control.index, now);
    if (isAllChecked) {
      if (isAllCheckedInOrder()) {
        activatedEvent!.outcomes.overallOutcome = OverallOutcome.finish;
        // Current.deactivate();
        SnackbarGlobal.show(
            'Congratulations! You have finished the ${activatedEvent!.event.nameDist}. Your '
            'elapsed time: ${activatedEvent!.elapsedTimeString}');
      } else {
        activatedEvent!.outcomes.overallOutcome = OverallOutcome.dnq;
        // Current.deactivate();
        SnackbarGlobal.show('Controls checked in wrong order. Disqualified!');
      }
    }

    assert(controlCheckInTime(control) != null); // should have just set this

    // TODO maybe slightly refactor?

    var report = Report(activatedEvent);
    report.constructReportAndSend(control: control, comment: comment);
  }

  static DateTime? controlCheckInTime(Control control) {
    return outcomes?.getControlCheckInTime(control.index);
  }

  static bool controlIsChecked(Control control) {
    return controlCheckInTime(control) != null;
  }
}
