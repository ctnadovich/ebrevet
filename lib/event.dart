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
import 'control.dart';
import 'time_till.dart';
import 'region.dart';
import 'app_settings.dart';
import 'mylogger.dart';
import 'utility.dart';

// The Event object documents an event details
// with no reference to who is riding the event
// or what the event outcomes are

class Event {
  bool valid = false;
  late String name;
  late DateTime startDateTime;
  late DateTime endDateTime;
  // late String date;
  late String distance; // Official distance in KM
  late String startCity;
  late String startState;
  late String eventSanction;
  late String eventType;
  String organizerName = "Not Set";
  String organizerPhone = 'Not Set';
  late int cueVersion;
  late String eventInfoUrl;
  late String
      eventID; // This must be unique worldwide (could be contstructed "$regionID-$regionEventID")

// For now, eventID is a String, but...
// Maybe the eventID needs to be wrapped in a class

  late int regionID; // Numeric ACP Club Code

// This should originate from the future_events top level tag checkin_post_url

  late String checkinPostURL;

  final List<Control> controls = [];

  Map<String, dynamic> get toMap => {
        'name': name,
        'start_datetime_utc': startDateTime.toUtc().toIso8601String(),
        'end_datetime_utc': endDateTime.toUtc().toIso8601String(),
        'distance': distance,
        'start_city': startCity,
        'start_state': startState,
        'sanction': eventSanction,
        'type': eventType,
        'cue_version': cueVersion,
        'organizer_name': organizerName,
        'organizer_phone': organizerPhone,
        'event_info_url': eventInfoUrl,
        'event_id': eventID,
        'club_acp_code': regionID,
        'checkin_post_url': checkinPostURL,
        'controls': [for (var cntrl in controls) cntrl.toMap],
      };

  Event.fromMap(Map<String, dynamic> json) {
    // try {
    name = json['name'];
    String startDateTimeUTCString = json['start_datetime_utc'];
    String endDateTimeUTCString = json['end_datetime_utc'];
    startDateTime = DateTime.parse(startDateTimeUTCString);
    endDateTime = DateTime.parse(endDateTimeUTCString);
    distance = json['distance'];
    startCity = json['start_city'];
    startState = json['start_state'];
    eventSanction = json['sanction'] ?? "?";
    eventType = json['type'] ?? "?";
    organizerName = json['organizer_name'] ?? "?";
    organizerPhone = json['organizer_phone'] ?? "?";
    eventInfoUrl = json['event_info_url'] ?? "";
    cueVersion = (json['cue_version'] is int)
        ? json['cue_version']
        : int.tryParse(json['cue_version'])!;
    eventID = json['event_id'];
    regionID = (json['club_acp_code'] is int)
        ? json['club_acp_code']
        : int.tryParse(json['club_acp_code'])!;

    if (false == json.containsKey('checkin_post_url') ||
        json['checkin_post_url']!.isEmpty) {
      throw const FormatException('No URL specified for upload');
    }
    checkinPostURL = json['checkin_post_url']!;

    List<dynamic> controlsListMap = json['controls'];
    MyLogger.entry(
        'Event.fromMap() restored $name from JSON. Found ${controlsListMap.length} controls.');
    controls.clear();
    for (var i = 0; i < controlsListMap.length; i++) {
      var controlMap = controlsListMap[i];
      var c = Control.fromMap(i, controlMap);
      if (c.valid) {
        controls.add(c);
      } else {
        break;
      }
    }
    valid = true;
    // } catch (error) {
    //   var etxt = "Error converting JSON future event response: $error";
    //   SnackbarGlobal.show(etxt);
    //   MyLogger.entry(etxt);
    // }
  }

  get nameDist {
    return '$name ${distance}K';
  }

  // The event_id from server must be unique worldwide
  // String get key {
  //   return "$regionID-$eventID";
  // }

  get dateTime {
    var sdtl = startDateTime.toLocal();
    if (sdtl.year == DateTime.now().toLocal().year) {
      return Utility.toBriefDateTimeString(
          sdtl); // sdtl.toString().substring(0, 16);
    } else {
      return Utility.toYearDateTimeString(sdtl);
    }
  }

  get startDate {
    var sdtl = startDateTime.toLocal();
    return sdtl.toString().substring(0, 10);
  }

  get statusText {
    DateTime now = DateTime.now();
    if (startDateTime.isAfter(now)) {
      // Event in future
      var tt = TimeTill(startDateTime);
      return "Starts in ${tt.interval} ${tt.unit}";
    } else if (endDateTime.isBefore(now)) {
      // Event in past
      var tt = TimeTill(endDateTime);
      return "Ended ${tt.interval} ${tt.unit} ago";
    } else {
      return 'Underway!';
    }
  }

  String get cueVersionString {
    if (cueVersion > 0) {
      return '$cueVersion';
    } else {
      return 'No cue sheet';
    }
  }

  int get finishControlKey {
    return controls.last.index;
  }

  int get startControlKey {
    return controls.first.index;
  }

  Region get region => Region(regionID: regionID);
  // String get ebrevetServerURL => region.ebrevetServerURL;
  // String get secret => region.secret;

  // Time window +/- from the official start time that
  // starts will be allowed. In minutes.

  bool get isStartable {
    var now = DateTime.now();
    var difference = startDateTime.difference(now);
    return (difference.inMinutes.abs() <
        AppSettings.startableTimeWindowMinutes);
  }

  bool get isPreridable {
    var now = DateTime.now();
    var difference = startDateTime.difference(now);
    return difference.inMinutes > AppSettings.startableTimeWindowMinutes &&
        (AppSettings.prerideDateWindowOverride ||
            difference.inDays <= AppSettings.prerideTimeWindowDays);
  }
}
