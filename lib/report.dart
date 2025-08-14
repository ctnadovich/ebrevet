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

import 'package:ebrevet_card/exception.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'control.dart';
import 'snackbarglobal.dart';
import 'location.dart';
import 'activated_event.dart';
import 'app_settings.dart';
import 'outcome.dart';
import 'mylogger.dart';
import 'signature.dart';

class Report {
  static late ActivatedEvent _reportingEvent;
  static String? reportURL;

  static void constructReportAndSend(
    ActivatedEvent pe, {
    Control? control,
    String? comment,
    Function? onUploadDone,
  }) {
    _reportingEvent = pe;

    Map<String, dynamic> report =
        _constructReport(controlIndex: control?.index, comment: comment);

    _sendReportToServer(report).then((response) {
      _recordReportResponse(response);
      onUploadDone?.call();
    }).catchError((e) {
      if (e is NoPreviousDataException) {
        SnackbarGlobal.show("Invalid event data: ${e.toString()}");
      } else {
        SnackbarGlobal.show("No Internet. "
            "Cannot upload results now. Try later.");
      }

      // Save the event history even if the upload was unsuccessful.
      // EventHistory.save();

      onUploadDone?.call();
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
        } else {
          result = ('Did not receive OK response. Server said: $status');
        }
      } catch (e) {
        result = ("Couldn't decode server response to report.");
      }
    } else {
      result =
          ("Error code ${response.statusCode} to URL: ${reportURL ?? 'null'}.");
    }

    if (result == null) {
      result = ('Check in data successfully uploaded to server.');
      // SnackbarGlobal.show(result);
    } else {
      SnackbarGlobal.show("Failed to upload checkin: $result");
    }

    // It may seem excessive to save the whole event history
    // every check in, but this certainly does the job.
    // The only time an event can change state is when
    // activated or at a control checkin.
    // EventHistory.save();

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

    if (_reportingEvent.outcomes.overallOutcome == OverallOutcome.finish) {
      report['finish_elapsed_time'] = _reportingEvent.elapsedTimeStringHHCMM;
    }

    report['app_version'] = AppSettings.version;
    report['proximity_radius'] = AppSettings.proximityRadius.toString();
    report['proximity_override'] =
        AppSettings.controlProximityOverride.toString();

    report['open_override'] = AppSettings.openTimeOverride.value ? "YES" : "NO";
    report['start_style'] = _reportingEvent.startStyle.name;

    report['rider_location'] = RiderLocation.latLongFullString;
    report['last_loc_update'] = RiderLocation.lastLocationUpdateUTCString;

    var timestamp = DateTime.now().toUtc().toIso8601String();
    report['timestamp'] = timestamp;
    report['signature'] =
        Signature.forReport(_reportingEvent, timestamp).cipherText;

    MyLogger.entry(
        severity: Severity.hidden,
        "Created report using secret '${_reportingEvent.event.region.secret}'");

    return report;
  }

  static Future<http.Response> _sendReportToServer(Map report) async {
    // assert(null != activatedEvent); // Never call this without activated event

    reportURL = _reportingEvent.event.checkinPostURL;

    if (reportURL == null || reportURL!.isEmpty) {
      throw NoPreviousDataException('No URL specified for upload');
    }

    var reportJSON = jsonEncode(report);

    // ,
    //     toEncodable: (Object? value) => value is EventOutcomes
    //         ? EventOutcomes.toJson(value)
    //         : throw FormatException('Cannot convert to JSON: $value'));

    MyLogger.entry("Sending JSON: $reportJSON");

    return http.post(
      Uri.parse(reportURL!),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: reportJSON,
    );
  }
}
