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

// import 'package:flutter/cupertino.dart';

import 'package:flutter_launcher_icons/custom_exceptions.dart';

import 'control.dart';
import 'time_till.dart';
import 'region.dart';
import 'app_settings.dart';
import 'utility.dart';

// MassStart -- Everyone gets the same start time. Automatic check in
// at the first control within the early/closing window. Distance
// to control doesn't matter.

// FreeStart -- Start time is individually determined by actual manual check-in at
// the first control, which must be within the early/late window
// and distance to control must be within proximity limit

// PreRide -- Start time is individually determined by actual manual check-in at
// the first control, which must be within the 15 day pre-ride window
// and before the early window and distance < proximity limit

// Permanent -- Start time is individually determined by actual manual check-in at
// the first control, which can be any time. Distance < proximity limit

enum StartStyle {
  massStart,
  freeStart,
  permanent,
  preRide;

  static Map _description = {
    massStart: 'Mass Start Brevet',
    freeStart: 'Free Start Brevet',
    permanent: 'Permanent',
    preRide: 'Volunteer pre-ride',
  };

  get description => _description[this];
}

enum EventFilter {
  future,
  past,
  permanent,
  all;

  static const _description = {
    EventFilter.future: 'Upcoming Events',
    EventFilter.past: 'Past Events',
    EventFilter.permanent: 'Permanents',
    EventFilter.all: 'All Events',
  };

  String get description => _description[this]!;
}

extension EventFilterX on EventFilter {
  // Filtering
  bool apply(Event e) {
    final now = DateTime.now();
    switch (this) {
      case EventFilter.future:
        return e.startDateTime != null &&
            e.latestFinishTime!.add(const Duration(hours: 12)).isAfter(now);
      case EventFilter.past:
        return e.startDateTime != null && e.startDateTime!.isBefore(now);
      case EventFilter.permanent:
        return e.startDateTime == null;
      case EventFilter.all:
        return true;
    }
  }

  // Sorting
  int compare(Event a, Event b) {
    switch (this) {
      case EventFilter.future:
        // Ascending by startDateTime; nulls last (shouldn’t occur after apply, but safe)
        final aStart = a.startDateTime, bStart = b.startDateTime;
        if (aStart == null && bStart == null) return 0;
        if (aStart == null) return 1;
        if (bStart == null) return -1;
        return aStart.compareTo(bStart);

      case EventFilter.past:
        // Descending by startDateTime; nulls last
        final aStart = a.startDateTime, bStart = b.startDateTime;
        if (aStart == null && bStart == null) return 0;
        if (aStart == null) return 1;
        if (bStart == null) return -1;
        return bStart.compareTo(aStart);

      case EventFilter.permanent:
      case EventFilter.all:
        // Alphabetical by name
        return a.name.compareTo(b.name);
    }
  }
}

class TimeWindow {
  Duration? early;
  Duration? late;
  DateTime? onTime;
  StartStyle startStyle;

  TimeWindow(this.startStyle, {this.onTime, this.early, this.late});

  Duration setEarlyTime(DateTime et) {
    if (onTime == null) {
      throw RangeError("Can't set early when onTime is null.");
    }
    if (et.isAfter(onTime!)) throw RangeError("Early time after start time.");
    early = onTime!.difference(et);
    return early!;
  }

  Duration setLateTime(DateTime lt) {
    if (onTime == null) throw RangeError("Can't set late when onTime is null.");
    if (lt.isBefore(onTime!)) throw RangeError("Late time before start time.");
    late = lt.difference(onTime!);
    return late!;
  }

  TimeWindow.fromJson(Map<String, dynamic> json)
      : early = Duration(minutes: (json['early'] ?? 0)),
        late = Duration(minutes: (json['late'] ?? 0)),
        startStyle = StartStyle.values.byName(json['start_style']),
        onTime = DateTime.tryParse(json['on_time'] ?? '');

  Map<String, dynamic> toJson() => {
        'early': early?.inMinutes ?? 0,
        'late': late?.inMinutes ?? 0,
        'on_time': onTime?.toUtc().toIso8601String() ?? '',
        'start_style': startStyle.name,
      };

  bool get earlyStartOK => early != null && early! > Duration.zero;
  bool get lateStartOK => late != null && late! > Duration.zero;
}

// The Event object documents an event details
// with no reference to who is riding the event
// or what the event outcomes are

class Event {
  bool valid = false;
  late String name;
  late TimeWindow startTimeWindow;
  // late DateTime endDateTime;
  late int distance; // Official distance in KM
  late int gravelDistance; // Official gravel in integer KM
  late String startCity;
  late String startState;
  late String eventSanction;
  late String eventType;
  String organizerName = "";
  String organizerPhone = '';
  late int cueVersion;
  late String eventInfoUrl;
  late String checkinStatusUrl;
  late String
      eventID; // This must be unique worldwide (could be contstructed "$regionID-$regionEventID")

// For now, eventID is a String, but...
// Maybe the eventID needs to be wrapped in a class

  late String regionID; // Numeric ACP Club Code

// This should originate from the future_events top level tag checkin_post_url

  late String checkinPostURL;

  final List<Control> controls = [];

  Map<String, dynamic> get toJson => {
        'name': name,
        'start_time_window': startTimeWindow.toJson(),
        // 'end_datetime_utc': endDateTime.toUtc().toIso8601String(),
        'distance': distance,
        'gravel_distance': gravelDistance,
        'start_city': startCity,
        'start_state': startState,
        'sanction': eventSanction,
        'type': eventType,
        'cue_version': cueVersion,
        'organizer_name': organizerName,
        'organizer_phone': organizerPhone,
        'event_info_url': eventInfoUrl,
        'checkin_status_url': checkinStatusUrl,
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
    if (json.containsKey('start_datetime_utc') &&
        json['start_datetime_utc'] != null) {
      // Legacy, simple start time
      startTimeWindow = TimeWindow(StartStyle.massStart,
          onTime: DateTime.parse(json['start_datetime_utc']));
    } else {
      startTimeWindow = TimeWindow.fromJson(json['start_time_window']);
    }
    // endDateTime = DateTime.parse(endDateTimeUTCString);
    distance = (json['distance'] is int)
        ? json['distance']
        : int.tryParse(json['distance'])!;
    gravelDistance = (json['gravel_distance'] is int)
        ? json['gravel_distance']
        : int.tryParse(json['gravel_distance'])!;
    startCity = json['start_city'];
    startState = json['start_state'];
    eventSanction = json['sanction'] ?? "?";
    eventType = json['type'] ?? "?";
    organizerName = json['organizer_name'] ?? "?";
    organizerPhone = json['organizer_phone'] ?? "?";
    eventInfoUrl = json['event_info_url'] ?? "";
    checkinStatusUrl = json['checkin_status_url'] ?? "";
    cueVersion = (json['cue_version'] is int)
        ? json['cue_version']
        : int.tryParse(json['cue_version'])!;
    eventID = json['event_id'];
    regionID = json['club_acp_code'].toString();

    //(json['club_acp_code'] is int)
    //    ? json['club_acp_code']
    //    : int.tryParse(json['club_acp_code'])!;

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

  DateTime? get startDateTime => startTimeWindow.onTime;

  DateTime get startControlOpenTime => controls[startControlKey].open;
  DateTime get startControlCloseTime => controls[startControlKey].close;
  DateTime get finishControlCloseTime => controls[finishControlKey].close;

  String openTimeString(int controlKey) =>
      controls[controlKey].open.toLocal().toString().substring(0, 16);
  String closeTimeString(int controlKey) =>
      controls[controlKey].close.toLocal().toString().substring(0, 16);

  Duration get allowedDuration {
    // if (startTimeWindow == null) return null; // Permanent
    return finishControlCloseTime.difference(startControlOpenTime);
  }

  // DateTime? get x xfinishDateTime {
  //   if (startTimeWindow.startStyle == StartStyle.permanent ||
  //       startTimeWindow.onTime == null) return null; // Permanent
  //   return startDateTime!.add(allowedDuration);
  // }

  DateTime? get latestStartTime => startTimeWindow.onTime
      ?.add(startTimeWindow.late ?? const Duration(days: 0));
  DateTime? get earliestStartTime => startTimeWindow.onTime
      ?.subtract(startTimeWindow.early ?? const Duration(days: 0));

  DateTime? get latestFinishTime => latestStartTime?.add(allowedDuration);
  DateTime? get earliestFinishTime => earliestStartTime?.add(allowedDuration);

  get isFuture {
    final now = DateTime.now();
    return finishControlCloseTime.isBefore(now);
  }

  get dateTime {
    if (startTimeWindow.startStyle == StartStyle.permanent ||
        startTimeWindow.onTime == null) {
      return "Ride any time";
    }
    var sdtl = startTimeWindow.onTime!.toLocal();
    var edtl =
        startTimeWindow.earlyStartOK ? earliestStartTime!.toLocal() : sdtl;
    var ldtl = startTimeWindow.lateStartOK ? latestStartTime!.toLocal() : sdtl;

    if (edtl.isAtSameMomentAs(ldtl)) {
      return Utility.toBriefDateTimeString(sdtl);
    } else {
      var es = Utility.toBriefDateTimeString(edtl);
      var ls = Utility.toBriefTimeString(ldtl);
      return "From $es to $ls";
    }
  }

  get startDate {
    if (startTimeWindow.startStyle == StartStyle.permanent ||
        startTimeWindow.onTime == null) {
      return "Any date";
    }

    var sdtl = startTimeWindow.onTime!.toLocal();
    return sdtl.toString().substring(0, 10);
  }

  get eventStatusText {
    if (startTimeWindow.startStyle == StartStyle.permanent ||
        startTimeWindow.onTime == null) {
      return "Any Time";
    }
    DateTime now = DateTime.now();
    if (earliestStartTime!.isAfter(now)) {
      // Event in future
      var tt = TimeTill(earliestStartTime!);
      return "Starts in ${tt.interval} ${tt.unit}";
    } else if (finishControlCloseTime.isBefore(now)) {
      // Event in past
      var tt = TimeTill(finishControlCloseTime);
      return "Ended ${tt.interval} ${tt.unit} ago";
    } else {
      return 'Underway!';
    }
  }

  get isUnderway {
    if (startTimeWindow.startStyle == StartStyle.permanent ||
        startTimeWindow.onTime == null) {
      return false;
    }
    DateTime now = DateTime.now();
    if (earliestStartTime!.isAfter(now)) {
      // Event in future
      return false;
    } else if (finishControlCloseTime.isBefore(now)) {
      // Event in past
      return false;
    } else {
      return true;
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

  bool get isGravel => (gravelDistance > 0);

  bool isIntermediateControl(control) =>
      control.index != finishControlKey && control.index != startControlKey;
  bool isFinishControl(control) => control.index == finishControlKey;

  bool isUntimedControl(Control c) {
    return c.style.isUntimedStyle ||
        (isIntermediateControl(c) && gravelDistance > 0) ||
        c.timed == false;
  }

  // Time window +/- from the official start time that
  // starts will be allowed. In minutes.

  bool get isStartable {
    var now = DateTime.now();
    var onTime = startTimeWindow.onTime;
    var early = startTimeWindow.early;
    var late = startTimeWindow.late;
    var answer = true;

    if (cueVersion <= 0) {
      answer = false; // Can't start without a published cuesheet
    } else {
      switch (startTimeWindow.startStyle) {
        case StartStyle.freeStart:
          if (onTime != null) {
            if (early != null) {
              var earlyTime = onTime.subtract(early);
              if (now.isBefore(earlyTime)) answer = false;
            } else if (late != null) {
              var lateTime = onTime.add(late);
              if (now.isAfter(lateTime)) answer = false;
            }
          }
          break;

        case StartStyle.massStart:
          if (onTime == null) {
            throw const InvalidConfigException(
                'Mass start events must have a start time');
          }
          var graceDuration =
              const Duration(minutes: AppSettings.advanceStartTimeGraceMinutes);
          var graceOpenTime = onTime.subtract(graceDuration);
          answer =
              graceOpenTime.isBefore(now) && startControlCloseTime.isAfter(now);
          break;

        case StartStyle.preRide:
          answer = isPreridable;
          break;

        case StartStyle.permanent:
          answer = true;
          break;
      }
    }

    return answer;
  }

  bool get isPreridable {
    var now = DateTime.now();
    var onTime = startTimeWindow.onTime;

    if (startTimeWindow.startStyle == StartStyle.permanent || onTime == null) {
      return false; // Can't pre-ride permanents
    }

    var difference = onTime.difference(now);
    var difMinutes = difference.inMinutes;
    // var difHours = difference.inHours;
    var preRideWindowMinutes = 24 * 60 * AppSettings.prerideTimeWindowDays;
    var preRideDisallowMinutes = 60 * AppSettings.prerideDisallowHours;
    return difMinutes > preRideDisallowMinutes &&
        (AppSettings.prerideDateWindowOverride.value ||
            difMinutes <= preRideWindowMinutes);
  }

  static int sort(Event a, Event b) {
    if (a.startTimeWindow.onTime == null) return 1;
    if (b.startTimeWindow.onTime == null) return -1;
    return a.startTimeWindow.onTime!.isAfter(b.startTimeWindow.onTime!)
        ? 1
        : (a.startTimeWindow.onTime!.isBefore(b.startTimeWindow.onTime!)
            ? -1
            : 0);
  }
}
