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

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'control.dart';
import 'snackbarglobal.dart';
import 'location.dart';
import 'event_history.dart';
import 'app_settings.dart';
import 'outcome.dart';
import 'mylogger.dart';
import 'signature.dart';

class Report {
  static late PastEvent _reportingEvent;

  static void constructReportAndSend(PastEvent pe,
      {Control? control, String? comment}) {
    _reportingEvent = pe;

    Map<String, dynamic> report =
        _constructReport(controlIndex: control?.index, comment: comment);

    _sendReportToServer(report)
        .then((response) => _recordReportResponse(response))
        .catchError((e) {
      SnackbarGlobal.show("No Internet. "
          "Cannot upload results now. Try later.");
    });
  }

  static void _recordReportResponse(http.Response response) {
    String? result;
    if (response.statusCode == 200) {
      try {
        var r = jsonDecode(response.body);
        var status = (r.containsKey('status')) ? r['status'] : '';
        if (status == 'OK') {
          var now = DateTime.now().toUtc();
          _reportingEvent.outcomes.lastUpload = now;
          EventHistory
              .save(); // It seems excessive to save the whole event history
          // every check in, but this certainly does the job.
          // The only time an event can change state is when
          // activated or at a control checkin.
        } else {
          result = ('Did not receive OK response. Got: $status');
        }
      } catch (e) {
        result = ("Couldn't decode server response to report.");
      }
    } else {
      result = ("Error response from server when sending report.");
    }

    if (result == null) {
      result = ('Check in data successfully uploaded to server.');
      // SnackbarGlobal.show(result);
    } else {
      SnackbarGlobal.show("Failed to upload checkin: $result");
    }
    MyLogger.entry(result);
    MyLogger.entry(
        "POST Status: ${response.statusCode}; Body: ${response.body}");
  }

  static Map<String, dynamic> _constructReport(
      {int? controlIndex, // Set if we are checking into a control
      String? comment // any text comment
      }) {
    // Never call this without activated event
    // assert(null != _activatedEvent);

    Map<String, dynamic> report = {};

    report['event_id'] = _reportingEvent.event.eventID.toString();
    report['rider_id'] = _reportingEvent.riderID;
    if (controlIndex != null) report['control_index'] = controlIndex.toString();
    if (comment != null) report['comment'] = comment;
    report['outcome'] = _reportingEvent.outcomes;

    report['app_version'] = AppSettings.version;
    report['proximity_radius'] = AppSettings.proximityRadius;
    report['open_override'] = AppSettings.openTimeOverride ? "YES" : "NO";
    report['preride'] = (_reportingEvent.isPreride) ? "YES" : "NO";

    report['rider_location'] = RiderLocation.latLongFullString;
    report['last_loc_update'] = RiderLocation.lastLocationUpdateUTCString;

    var timestamp = DateTime.now().toUtc().toIso8601String();
    report['timestamp'] = timestamp;
    var signature = Signature(
        riderID: _reportingEvent.riderID, // non null by assertion above
        event: _reportingEvent.event,
        data: timestamp,
        codeLength: 8);

    report['signature'] = signature.text;
    return report;
  }

  static Future<http.Response> _sendReportToServer(Map report) {
    // assert(null != activatedEvent); // Never call this without activated event

    var eventURL = _reportingEvent.event.eventURL;
    var url = "$eventURL/post_checkin";
    var reportJSON = jsonEncode(report,
        toEncodable: (Object? value) => value is EventOutcomes
            ? EventOutcomes.toJson(value)
            : throw FormatException('Cannot convert to JSON: $value'));

    MyLogger.entry("Sending JSON: $reportJSON");

    return http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: reportJSON,
    );
  }
}
