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

// import 'package:flutter/material.dart';

import 'control.dart';
import 'time_till.dart';
import 'region.dart';
import 'app_settings.dart';
import 'mylogger.dart';
import 'utility.dart';

class TimeWindow {
  Duration? early;
  Duration? late;
  DateTime onTime;
  bool freeStart = false;

  TimeWindow(this.onTime, {this.early, this.late});

  Duration setEarlyTime(DateTime et) {
    if (et.isAfter(onTime)) throw RangeError("Early time after start time.");
    early = onTime.difference(et);
    return early!;
  }

  Duration setLateTime(DateTime lt) {
    if (lt.isBefore(onTime)) throw RangeError("Late time before start time.");
    late = lt.difference(onTime);
    return late!;
  }

  DateTime? get lateTime => onTime.add(late ?? const Duration(days: 0));
  DateTime? get earlyTime => onTime.subtract(early ?? const Duration(days: 0));

  TimeWindow.fromJson(Map<String, dynamic> json)
      : early = Duration(minutes: (json['early'] ?? 0)),
        late = Duration(minutes: (json['late'] ?? 0)),
        freeStart =
            (json['free_start'] as String?)?.toUpperCase().contains("YES") ??
                false,
        onTime = DateTime.parse(json['on_time']);

  Map<String, dynamic> toJson() => {
        'early': early?.inMinutes ?? 0,
        'late': late?.inMinutes ?? 0,
        'on_time': onTime.toUtc().toIso8601String(),
        'free_start': freeStart ? "YES" : "NO",
      };
}

// The Event object documents an event details
// with no reference to who is riding the event
// or what the event outcomes are

class Event {
  bool valid = false;
  late String name;
  TimeWindow? startTimeWindow;
  // late DateTime endDateTime;
  late String distance; // Official distance in KM
  late String startCity;
  late String startState;
  late String eventSanction;
  late String eventType;
  String organizerName = "";
  String organizerPhone = '';
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

  Map<String, dynamic> get toJson => {
        'name': name,
        'start_time_window': startTimeWindow?.toJson() ?? "PERMANENT",
        // 'end_datetime_utc': endDateTime.toUtc().toIso8601String(),
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

  Event.fromJson(Map<String, dynamic> json) {
    // try {
    name = json['name'];
    // String? startDateTimeUTCString = json['start_datetime_utc'];
    // String? endDateTimeUTCString = json['end_datetime_utc'];
    if (json.containsKey('start_time_window') &&
        json['start_time_window'] != null) {
      startTimeWindow = TimeWindow.fromJson(json['start_time_window']);
    } else if (json.containsKey('start_datetime_utc') &&
        json['start_datetime_utc'] != null) {
      startTimeWindow = TimeWindow(DateTime.parse(json['start_datetime_utc']));
    }
    // endDateTime = DateTime.parse(endDateTimeUTCString);
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
    // MyLogger.entry(
    //     'Event.fromMap() restored $name from JSON. Found ${controlsListMap.length} controls.');
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

  DateTime? get startDateTime => startTimeWindow?.onTime;

  DateTime get startControlOpenTime => controls[startControlKey].open;
  DateTime get startControlCloseTime => controls[startControlKey].close;
  DateTime get finishControlCloseTime => controls[finishControlKey].close;

  Duration? get allowedDuration {
    if (startTimeWindow == null) return null; // Permanent
    return finishControlCloseTime.difference(startControlOpenTime);
  }

  DateTime? get finishDateTime {
    if (startTimeWindow == null) return null; // Permanent
    return startDateTime!.add(allowedDuration!);
  }

  get dateTime {
    if (startTimeWindow == null) return "Any time";
    var sdtl = startTimeWindow!.onTime.toLocal();
    if (sdtl.year == DateTime.now().toLocal().year) {
      return Utility.toBriefDateTimeString(
          sdtl); // sdtl.toString().substring(0, 16);
    } else {
      return Utility.toYearDateTimeString(sdtl);
    }
  }

  get startDate {
    if (startTimeWindow == null) return "Any date";

    var sdtl = startTimeWindow!.onTime.toLocal();
    return sdtl.toString().substring(0, 10);
  }

  get eventStatusText {
    if (startTimeWindow == null) return "Permanent";
    DateTime now = DateTime.now();
    if (startTimeWindow!.onTime.isAfter(now)) {
      // Event in future
      var tt = TimeTill(startTimeWindow!.onTime);
      return "Starts in ${tt.interval} ${tt.unit}";
    } else if (finishControlCloseTime.isBefore(now)) {
      // Event in past
      var tt = TimeTill(finishControlCloseTime);
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
    if (startTimeWindow == null) return true; // Permanent
    var now = DateTime.now();
    var onTime = startTimeWindow!.onTime;

    if (startTimeWindow!.freeStart) {
      // Free start
      if (startTimeWindow!.early != null) {
        var earlyTime = onTime.subtract(startTimeWindow!.early!);
        if (now.isBefore(earlyTime)) return false;
      }
      if (startTimeWindow!.late != null) {
        var lateTime = onTime.add(startTimeWindow!.late!);
        if (now.isAfter(lateTime)) return false;
      }
      return true;
    } else {
      // Regular start with "grace"
      var graceDuration =
          const Duration(minutes: AppSettings.advanceStartTimeGraceMinutes);
      var graceOpenTime = startTimeWindow!.onTime.subtract(graceDuration);
      return graceOpenTime.isBefore(now) && startControlCloseTime.isAfter(now);
    }
  }

  bool get isPreridable {
    if (startTimeWindow == null) return false; // Can't pre-ride permanents

    var now = DateTime.now();
    var difference = startTimeWindow!.onTime.difference(now);
    return difference.inMinutes > AppSettings.advanceStartTimeGraceMinutes &&
        (AppSettings.prerideDateWindowOverride.value ||
            difference.inDays <= AppSettings.prerideTimeWindowDays);
  }

  static int sort(Event a, Event b) {
    if (a.startTimeWindow == null) return 1;
    if (b.startTimeWindow == null) return -1;
    return a.startTimeWindow!.onTime.isAfter(b.startTimeWindow!.onTime)
        ? 1
        : (a.startTimeWindow!.onTime.isBefore(b.startTimeWindow!.onTime)
            ? -1
            : 0);
  }
}
