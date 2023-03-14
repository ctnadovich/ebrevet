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

// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'snackbarglobal.dart';
import 'event.dart';
// import 'rider.dart';
// import 'region.dart';
import 'outcome.dart';
import 'control.dart';
import 'location.dart';
import 'event_history.dart';
import 'signature.dart';
import 'app_settings.dart';
import 'logger.dart';

// Class for doing stuff with the the current context of event/rider/region
// The Event class has a static "current" that holds one of these during the ride

class Current {
  static PastEvent? activatedEvent;

  // The event we are riding NOW, stored in EventHistory

  static void activate(Event e, String riderID, {bool isPreride = false}) {
    activatedEvent = EventHistory.addActivate(e, riderID, isPreride);
    Logger.print(
        "Activated ${activatedEvent!.event.nameDist}${isPreride ? ' PRERIDE' : ''}");
  }

  static void deactivate() => activatedEvent=null;

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

    EventHistory.save(); // It seems excessive to save the whole event history
    // every check in, but this certainly does the job.
    // The only time an event can change state is when
    // activated or at a control checkin.

    assert(controlCheckInTime(control) != null); // should have just set this

    constructReportAndSend(control: control, comment: comment);
  }

  static void constructReportAndSend({Control? control, String? comment}) {
    Map<String, dynamic> report =
        constructReport(controlIndex: control?.index, comment: comment);

    sendReportToServer(report)
        .then((response) => recordReportResponse(response))
        .catchError((e) {
      SnackbarGlobal.show("No Internet. "
          "No worries. Try upload later. RIDE ON!");
    });
  }

  static ValueNotifier<DateTime?> lastSuccessfulServerUpload =
      ValueNotifier(null);

  static void recordReportResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        var r = jsonDecode(response.body);
        if (r.containsKey('status') && r['status'] == 'OK') {
          var now = DateTime.now().toUtc();
          activatedEvent!.outcomes.lastUpload = now;
          lastSuccessfulServerUpload.value = now;

          Logger.print('Check in successfully reported to server.');
        }
      } catch (e) {
        Logger.print("Couldn't decode server response to report.");
      }
    } else {
      Logger.print("Error response from server when sending report.");
    }

    Logger.print("POST Status: ${response.statusCode}; Body: ${response.body}");
  }


  static Map<String, dynamic> constructReport(
      {int? controlIndex, // Set if we are checking into a control
      String? comment // any text comment
      }) {
    // Never call this without activated event
    assert(null != activatedEvent);

    Map<String, dynamic> report = {};

    report['event_id'] = activatedEvent!.event.eventID.toString();
    report['rider_id'] = activatedEvent!.riderID;
    if (controlIndex != null) report['control_index'] = controlIndex.toString();
    if (comment != null) report['comment'] = comment;
    report['outcome'] = outcomes!;

    report['app_version']=AppSettings.version;
    report['proximity_radius']=AppSettings.proximityRadius;
    report['open_override']=AppSettings.openTimeOverride?"YES":"NO";
    report['preride']= (activatedEvent!.isPreride)?"YES":"NO";

    report['rider_location'] = RiderLocation.latLongFullString;
    report['last_loc_update'] = RiderLocation.lastLocationUpdateUTCString;

    var timestamp = DateTime.now().toUtc().toIso8601String();
    report['timestamp'] = timestamp;
    var signature = Signature(
        riderID: activatedEvent!.riderID, // non null by assertion above
        event: event!,
        data: timestamp,
        codeLength: 8);

    report['signature'] = signature.text;
    return report;
  }

  static Future<http.Response> sendReportToServer(Map report) {
    assert(null != activatedEvent); // Never call this without activated event

    var eventURL = activatedEvent!.event.eventURL;
    var url = "$eventURL/post_checkin";
    var reportJSON = jsonEncode(report,
        toEncodable: (Object? value) => value is EventOutcomes
            ? EventOutcomes.toJson(value)
            : throw FormatException('Cannot convert to JSON: $value'));

    Logger.print("Sending JSON: $reportJSON");

    return http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: reportJSON,
    );
  }

  static DateTime? controlCheckInTime(Control control) {
    return outcomes?.getControlCheckInTime(control.index);
  }

  static bool controlIsChecked(Control control) {
    return controlCheckInTime(control) != null;
  }
}
