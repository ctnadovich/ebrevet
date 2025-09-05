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

import 'package:ebrevet_card/mylogger.dart';

import 'exception.dart';
import 'dart:convert';
import 'report.dart';
import 'utility.dart';
import 'control.dart';
import 'dart:math';
import 'snackbarglobal.dart';
import 'activated_event.dart';

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

  /// Converts a JSON list of rider results into a list of RiderResults objects
  static List<RiderResults> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => RiderResults.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<RiderResults>> fetchAllFromServer(
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

  List<RiderComment> extractComments() {
    final comments = <RiderComment>[];

    for (final entry in checklist) {
      final text = entry.comment?.trim();
      if (text != null &&
          text.isNotEmpty &&
          !text.contains("Automatic Check In")) {
        comments.add(
          RiderComment(
            riderId: riderId,
            riderName: riderName,
            controlIndex: entry.index,
            text: text,
            dateTime: entry.checkinDatetime,
          ),
        );
      }
    }
    return comments;
  }

  static Future<List<RiderComment>> fetchAllComments(
      String checkinStatusUrl) async {
    final riders = await fetchAllFromServer(checkinStatusUrl);
    return riders.expand((r) => r.extractComments()).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime)); // optional sorting
  }

  // Make this a map so if we change events we start over, but
  // don't forget where we were if we go back

  static final Map<String, DateTime> _lastFetchTime = {};

  /// Fetches new comments since the last fetch.
  /// If [excludeRiderID] is provided, comments from that rider will be excluded.
  static Future<List<RiderComment>> fetchNewComments(
    ActivatedEvent activatedEvent, {
    String? excludeRiderID,
    bool allNew = false,
  }) async {
    try {
      final checkinStatusUrl = activatedEvent.event.checkinStatusUrl;
      final eventID = activatedEvent.event.eventID;
      final allResults = await fetchAllFromServer(checkinStatusUrl);

      final now = DateTime.now();
      final cutoff = _lastFetchTime[eventID] ?? now;

      final newComments = <RiderComment>[];

      for (final result in allResults) {
        final riderComments = result.extractComments();

        newComments.addAll(riderComments.where((c) {
          if (excludeRiderID != null && c.riderId == excludeRiderID) {
            return false; // skip own comments
          }
          return allNew || c.dateTime.isAfter(cutoff);
        }));
      }

      newComments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      _lastFetchTime[eventID] = now;
      return newComments;
    } catch (e) {
      MyLogger.entry("Error fetching new comments: $e");
      return [];
    }
  }
}

extension RiderCommentSorting on List<RiderComment> {
  void sortByDateTime({bool ascending = true}) {
    sort((a, b) => ascending
        ? a.dateTime.compareTo(b.dateTime)
        : b.dateTime.compareTo(a.dateTime));
  }

  void sortByRiderThenDateTime({bool ascending = true}) {
    sort((a, b) {
      final riderCmp = a.riderName.compareTo(b.riderName);
      if (riderCmp != 0) return riderCmp;
      return ascending
          ? a.dateTime.compareTo(b.dateTime)
          : b.dateTime.compareTo(a.dateTime);
    });
  }
}

class CommentFetcher {
  static final _random = Random();
  static const List<String> _talkVerbs = [
    "added",
    "announced",
    "answered",
    "articulated",
    "asserted",
    "boasted",
    "commented",
    "communicated",
    "confided",
    "contributed",
    "conveyed",
    "declared",
    "explained",
    "exclaimed",
    "grumbled",
    "hinted",
    "indicated",
    "insisted",
    "lamented",
    "manifested",
    "mentioned",
    "murmured",
    "muttered",
    "noted",
    "observed",
    "offered",
    "opined",
    "presented",
    "proclaimed",
    "quipped",
    "related",
    "remarked",
    "rejoined",
    "replied",
    "reported",
    "responded",
    "revealed",
    "said",
    "shared",
    "shouted",
    "signified",
    "suggested",
    "stated",
    "uttered",
    "vented",
    "voiced",
    "whispered",
    "wrote",
    "yelled",
  ];

  /// Call this whenever you want to fetch new comments manually.
  static Future<void> fetchAndFlush(ActivatedEvent activatedEvent,
      {String? excludeRiderID, bool allNew = false, Duration? delay}) async {
    try {
      final newComments = await RiderResults.fetchNewComments(activatedEvent,
          allNew: allNew, excludeRiderID: excludeRiderID);

      if (newComments.isEmpty) {
        MyLogger.entry("No new comments to display.");
      } else {
        if (delay != null) await Future.delayed(delay);

        MyLogger.entry("Found ${newComments.length} comments to display.");

        final msgList = newComments.map((c) {
          final verb = _talkVerbs[_random.nextInt(_talkVerbs.length)];
          final controlName =
              activatedEvent.event.controls[c.controlIndex - 1].name;
          final controlDistance =
              activatedEvent.event.controls[c.controlIndex - 1].distMi;

          return "${c.riderName} at $controlName ($controlDistance mi) $verb: '${c.text}'";
        }).toList();

        for (final msg in msgList) {
          FlushbarGlobal.show(msg, style: FlushbarStyle.comment);
        }
      }
    } catch (e, st) {
      MyLogger.entry(
          "Failed to fetch comments from URL ${activatedEvent.event.checkinStatusUrl}\n ERROR: $e\n$st");
      // Do not update _lastFetchTime
    }
  }
}

class RiderComment {
  final String riderId;
  final String riderName;
  final int controlIndex;
  final String text;
  final DateTime dateTime;

  RiderComment({
    required this.riderId,
    required this.riderName,
    required this.controlIndex,
    required this.text,
    required this.dateTime,
  });
}

// class TimelineCheckin {
//   final String riderName;
//   final int controlIndex;
//   final DateTime checkinTime;
//   final String? comment;

//   TimelineCheckin({
//     required this.riderName,
//     required this.controlIndex,
//     required this.checkinTime,
//     required this.comment,
//   });
// }

extension RiderCheckinsTimeline on List<RiderResults> {
  List<RiderComment> toTimeline() {
    final allCheckins = <RiderComment>[];

    for (final rider in this) {
      // Skip preride riders entirely
      if (rider.isReallyPreride == true) continue;

      for (int i = 0; i < rider.checklist.length; i++) {
        final checkin = rider.checklist[i];

        allCheckins.add(RiderComment(
          riderName: rider.riderName,
          riderId: rider.riderId,
          controlIndex: i + 1,
          dateTime: checkin.checkinDatetime,
          text: checkin.comment ?? '',
        ));
      }
    }

    allCheckins.sortByDateTime();
    return allCheckins;
  }
}
