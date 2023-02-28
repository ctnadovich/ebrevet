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

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'snackbarglobal.dart';
import 'event.dart';
import 'rider.dart';
import 'region.dart';
import 'outcome.dart';
import 'control.dart';
import 'location.dart';
import 'event_history.dart';
import 'signature.dart';

// Class for doing stuff with the the current context of event/rider/region
// The Event class has a static "current" that holds one of these during the ride

class Current {
  static PastEvent?
      activatedEvent; // The event we are riding NOW, stored in EventHistory
  static Rider? rider; // the rider riding this event
  static Region? region; // the region we are in


// We shouldn't have to worry about activating an event downloaded by a different rider in a different region
// because settings will delete events if the rider changes and the eventID is globally unique 

  static void activate(Event e, Rider r, Region g, {bool? preRideMode}) {
    rider = r;
    region = g;
    activatedEvent = _activate(e, preRideMode ?? false);

    print("Activated ${activatedEvent!.event.nameDist}");
  }

  static Event? get event {return activatedEvent?.event;}
  static EventOutcomes? get outcomes {return activatedEvent?.outcomes;}

  static PastEvent _activate(Event e, bool preRideMode) {
    var pe = EventHistory.lookupPastEvent(e.eventID);
    if (pe != null) {
      pe.outcomes.overallOutcome = OverallOutcome.active;   
    } else {
      pe = EventHistory.add(e, overallOutcome: OverallOutcome.active, preRideMode: preRideMode);  // need to save EventHistory now
    }      

    EventHistory.save();  

    // It seems excessive to save the whole event history
    // every activation, but this certainly does the job. 
    // The only time an event can change state is when 
    // activated or at a control checkin. 

    // once an event is "activated" it gets copied to past events and becomes immutable -- only the outcome can change
    // so conceivably the preriders could have a different "event" saved than the day-of riders


    return pe;

  }

  // static void clear() {
  //   rider = null;
  //   region = null;
  //   activatedEvent = null;
  // }

  // static void deactivate() {
  //   clear();
  // }

  static bool get isActivated {
    return (rider??region??activatedEvent)!=null;
  }

  static bool get isAllChecked {
    if (event == null) return false;
    for (var control in event!.controls) {
      if (false == controlIsChecked(control)) return false;
    }
    return true;
  }

  static bool isAllCheckedInOrder() {
    if (event == null) return false;
    if (controlCheckInTime(event!.controls.first) == null) return false;
    DateTime tLast = Control.isPrerideMode ? controlCheckInTime(event!.controls.first)! :  event!.startDateTime;
    for (var control in event!.controls) {
      var tControl = controlCheckInTime(control);
      if (tControl == null) return false;
      if (tControl.isBefore(tLast)) return false;
      tLast = tControl;
    }

    if (activatedEvent!.elapsedDuration == null) return false;

    return true;
  }

  static void controlCheckIn(Control control) {

      // TODO the checks below should never happen. MAybe need diffent exception class? 

    if (activatedEvent == null) {
      SnackbarGlobal.show('Trying to check into an unavailable event');
      return;
    }

    if (false == control.isAvailable) {
      SnackbarGlobal.show('Trying to check into an unavailable control');
      return;
    }

    var eventID = activatedEvent!.event.eventID;
    if (null == EventHistory.lookupPastEvent(eventID)) {
      SnackbarGlobal.show('Trying to check into an inactive event.');
      return;
    }

    var now = DateTime.now().toUtc();
    activatedEvent!.outcomes.setControlCheckInTime(control.index,now);  
    if (isAllChecked) {
      if (isAllCheckedInOrder()) {
        activatedEvent!.outcomes.overallOutcome = OverallOutcome.finish;
        SnackbarGlobal.show(
            'Congratulations! You have finished the ${activatedEvent!.event.nameDist}. Your '
            'elapsed time: ${activatedEvent!.elapsedTimeString}');
      } else {
        activatedEvent!.outcomes.overallOutcome = OverallOutcome.dnq;
        SnackbarGlobal.show('Controls checked in wrong order. Disqualified!');
      }
    }

    EventHistory.save();  // It seems excessive to save the whole event history
                          // every check in, but this certainly does the job. 
                          // The only time an event can change state is when 
                          // activated or at a control checkin. 

    assert(controlCheckInTime(control) != null);  // TODO or maybe a special exception as above? 

    Map<String, dynamic> report = constructReport(controlIndex: control.index);

    sendReportToServer(report)
        .then((response) => print(
            "POST Status: ${response.statusCode}; Body: ${response.body}"))
        .catchError((e) =>
            SnackbarGlobal.show("Checked in on app, but not on Internet. "
                "No worries. Will try to send report later. RIDE ON!"));
  }

  static Map<String, dynamic> constructReport(
      {int? controlIndex, // Set if we are checking into a control
      String? comment // any text comment
      }) {
    
    // Never call this without activated event    
    assert(null != event &&
        null != rider &&
        null != outcomes &&
        null != region); 

    Map<String, dynamic> report = {};

    report['event_id'] = event!.eventID.toString();
    report['rider_id'] = rider!.rusaID;
    if (controlIndex != null) report['control_index'] = controlIndex.toString();
    if (comment != null) report['comment'] = comment;
    report['outcome'] = outcomes!;

    if (Control.isPrerideMode) report['preride'] = "YES";

    report['rider_location'] = RiderLocation.latLongFullString;
    report['last_loc_update'] = RiderLocation.lastLocationUpdateUTCString;

    var timestamp = DateTime.now().toUtc().toIso8601String();
    report['timestamp'] = timestamp;
    var signature = Signature(
      rider: rider!,  // non null by assertion above
      region: region!,
      event: event!,
      data: timestamp, codeLength: 8);

    report['signature'] = signature.text;
    return report;
  }

  static Future<http.Response> sendReportToServer(Map report) {
    assert(null != activatedEvent &&
        null != rider &&
        null != region); // Never call this without activated event

    var eventURL = region!.eventURL;
    var url = "$eventURL/post_checkin";
    var reportJSON = jsonEncode(report,
        toEncodable: (Object? value) => value is EventOutcomes
            ? EventOutcomes.toJson(value)
            : throw Exception('Cannot convert to JSON: $value'));

    print("Sending JSON: $reportJSON");

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
