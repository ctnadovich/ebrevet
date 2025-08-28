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

import 'exception.dart';
import 'dart:convert';
import 'report.dart';
import 'utility.dart';
import 'control.dart';

class Checkin {
  final DateTime checkinDatetime;
  final String? comment;
  final bool? isEarly;
  final bool? isLate;
  final int index; // 1-based index in the checklist

  Checkin({
    required this.checkinDatetime,
    this.comment,
    this.isEarly,
    this.isLate,
    required this.index,
  });

  factory Checkin.fromJson(Map<String, dynamic> json, int index) {
    return Checkin(
      checkinDatetime: DateTime.parse(json['checkin_datetime']).toLocal(),
      comment: json['comment'] as String?,
      isEarly: json['is_earlyq'] as bool?,
      isLate: json['is_lateq'] as bool?,
      index: index,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkin_datetime': checkinDatetime.toIso8601String(),
      'comment': comment,
      'is_earlyq': isEarly,
      'is_lateq': isLate,
      'index': index,
    };
  }

  String formatCheckinWithControlTimes(Control control) {
    final controlNum = control.index + 1;
    final checkinTime = Utility.toBriefDateTimeString(checkinDatetime);
    final warning = (isEarly == true || isLate == true) ? ' ⚠️' : '';

    return "Control $controlNum: $checkinTime $warning";
  }
}

class RiderResults {
  final String riderId;
  final String riderName;
  final List<Checkin> checklist;
  final String result;
  final Duration? elapsedTime;
  final bool? isReallyPreride;

  RiderResults({
    required this.riderId,
    required this.riderName,
    required this.checklist,
    required this.result,
    this.elapsedTime,
    required this.isReallyPreride,
  });

  factory RiderResults.xfromJson(Map<String, dynamic> json) {
    final rawChecklist = json['checklist'] as List<dynamic>? ?? [];
    final List<Checkin> checkins = [];

    bool anyPreride = false;

    for (int i = 0; i < rawChecklist.length; i++) {
      final item = rawChecklist[i] as Map<String, dynamic>;
      final checkin = Checkin.fromJson(item, i + 1);
      checkins.add(checkin);

      if (item['is_prerideq'] == true) {
        anyPreride = true;
      }
    }

    return RiderResults(
      riderId: json['rider_id'] as String,
      riderName: json['rider_name'] as String,
      checklist: checkins,
      result: (json['result'] ?? '').toString(),
      elapsedTime: _parseElapsedTime(json['elapsed_time'] as String?),
      isReallyPreride: anyPreride,
    );
  }

  factory RiderResults.fromJson(Map<String, dynamic> json) {
    final rawChecklist = json['checklist'] as List<dynamic>? ?? [];
    final List<Checkin> checkins = [];

    bool? anyPreride; // start as null

    for (int i = 0; i < rawChecklist.length; i++) {
      final item = rawChecklist[i] as Map<String, dynamic>?;

      if (item != null) {
        final checkin = Checkin.fromJson(item, i + 1);
        checkins.add(checkin);

        if (item['is_prerideq'] == true) {
          anyPreride = true;
        } else {
          anyPreride ??= false;
        }
      }
    }

    return RiderResults(
      riderId: json['rider_id'] as String,
      riderName: json['rider_name'] as String,
      checklist: checkins,
      result: (json['result'] ?? '').toString(),
      elapsedTime: _parseElapsedTime(json['elapsed_time'] as String?),
      isReallyPreride: anyPreride, // can be null if no checkins
    );
  }

  /// Converts a JSON list into a list of RiderResults
  static List<RiderResults> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => RiderResults.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<RiderResults>> fetchFromServer(
      String checkinStatusUrl) async {
    final url = "$checkinStatusUrl/json";
    final responseBody = await Report.fetchResponseFromServer(url);

    final decodedResponse = jsonDecode(responseBody) as List<dynamic>;
    if (decodedResponse.isEmpty) {
      throw ServerException('Empty response from $url');
    }

    return fromJsonList(decodedResponse);
  }

  static Duration? _parseElapsedTime(String? elapsed) {
    if (elapsed == null) return null;
    final parts = elapsed.split(':').map(int.parse).toList();
    if (parts.length != 3) return null;
    return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
  }

  String formatElapsedHHMM() {
    if (elapsedTime == null) return "--:--";

    final hours = elapsedTime!.inHours;
    final minutes = elapsedTime!.inMinutes.remainder(60);

    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');

    return "$hh:$mm";
  }

  List<Map<String, dynamic>> extractComments() {
    final comments = <Map<String, dynamic>>[];

    for (int i = 0; i < checklist.length; i++) {
      final entry = checklist[i];
      final comment = entry.comment;
      if (comment != null) {
        final text = comment.toString().trim();
        if (text.isNotEmpty && !text.contains("Automatic Check In")) {
          comments.add({
            'index': entry.index,
            'comment': text,
          });
        }
      }
    }

    return comments;
  }
}

class TimelineCheckin {
  final String riderName;
  final int controlIndex;
  final DateTime checkinTime;
  final String? comment;

  TimelineCheckin({
    required this.riderName,
    required this.controlIndex,
    required this.checkinTime,
    required this.comment,
  });
}

extension RiderCheckinsTimeline on List<RiderResults> {
  List<TimelineCheckin> toTimeline() {
    final allCheckins = <TimelineCheckin>[];

    for (final rider in this) {
      // Skip preride riders entirely
      if (rider.isReallyPreride == true) continue;

      for (int i = 0; i < rider.checklist.length; i++) {
        final checkin = rider.checklist[i];

        allCheckins.add(TimelineCheckin(
          riderName: rider.riderName,
          controlIndex: i + 1,
          checkinTime: checkin.checkinDatetime,
          comment: checkin.comment,
        ));
      }
    }

    allCheckins.sort((a, b) => b.checkinTime.compareTo(a.checkinTime));
    return allCheckins;
  }
}
