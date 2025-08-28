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

import 'mylogger.dart';
import 'utility.dart';

enum OverallOutcome {
  dns,
  dnf,
  dnqSkipped,
  dnqScrambled,
  dnqLateCheckIn,
  finish,
  active,
  unknown;

  bool get isDNQ =>
      this == dnqSkipped || this == dnqScrambled || this == dnqLateCheckIn;

  static Map _description = {
    dns: 'Did Not Ride',
    dnf: 'Did Not Finish',
    dnqSkipped: 'RBA Review: skipped control',
    dnqScrambled: 'RBA Review: control order',
    dnqLateCheckIn: 'RBA Review: late to control',
    finish: 'Finished',
    active: 'Riding Now',
    unknown: 'Unknown',
  };

  get description => _description[this];
}

// The plural (outcomeS versus outcome) refers to the multiple outcomes within a single event -- overall and control times

class EventOutcomes {
  late OverallOutcome _overallOutcome;
  late Map<int, DateTime> _checkInTimeMap; // control number -> check in time
  late Map<int, String> _checkInCommentMap; // control number -> comment

  DateTime?
      lastUpload; // If using this setter don't forget to save event history

  EventOutcomes({
    OverallOutcome? overallOutcome,
    Map<int, DateTime>? checkInTimeMap,
    Map<int, String>? checkInCommentMap,
    // bool? isPreride,
  }) {
    _checkInTimeMap = checkInTimeMap ?? {};
    _checkInCommentMap = checkInCommentMap ?? {};
    _overallOutcome = overallOutcome ?? OverallOutcome.dns;
  }

  Map<String, dynamic> toJson() => {
        'overall_outcome': _overallOutcome.name,
        'last_upload': lastUpload?.toUtc().toIso8601String(),
        'check_in_times': _checkInTimeMap.map((key, value) =>
            MapEntry(key.toString(), value.toUtc().toIso8601String())),
        'check_in_comments': _checkInCommentMap
            .map((key, value) => MapEntry(key.toString(), value)),
      };

  factory EventOutcomes.fromJson(Map<String, dynamic> jsonMap) {
    var eo = EventOutcomes();
    eo._overallOutcome =
        OverallOutcome.values.byName(jsonMap['overall_outcome']);
    Map<String, dynamic> checkInJsonMap = jsonMap['check_in_times'];
    eo._checkInTimeMap
        .clear(); // not needed as default constructor will make this empty anyway
    for (var k in checkInJsonMap.keys) {
      int kInt = int.parse(k);
      DateTime vDateTime = DateTime.parse(checkInJsonMap[k]);
      eo._checkInTimeMap[kInt] = vDateTime;
    }
    Map<String, dynamic> checkInCommentJsonMap = jsonMap['check_in_comments'];
    eo._checkInCommentMap
        .clear(); // not needed as default constructor will make this empty anyway
    for (var k in checkInCommentJsonMap.keys) {
      int kInt = int.parse(k);
      var comment = checkInCommentJsonMap[k];
      eo._checkInCommentMap[kInt] = comment;
    }
    if (jsonMap['last_upload'] != null) {
      eo.lastUpload = DateTime.parse(jsonMap['last_upload']);
    }
    return eo;
  }

  // When using this setter, don't forget to call EventHistory.save() afterwards

  void setControlCheckInTime(int controlKey, DateTime t) {
    _checkInTimeMap[controlKey] = t;
  }

  void setControlCheckInComment(int controlKey, String t) {
    _checkInCommentMap[controlKey] = t;
  }

  DateTime? getControlCheckInTime(int controlKey) {
    return _checkInTimeMap[controlKey];
  }

  String? getControlCheckInComment(int controlKey) {
    return _checkInCommentMap[controlKey];
  }

  OverallOutcome get overallOutcome {
    return _overallOutcome;
  }

  String get lastUploadString => Utility.toBriefDateTimeString(lastUpload);

  // When using this setter, don't forget to call EventHistory.save() afterwards

  set overallOutcome(OverallOutcome oo) {
    MyLogger.entry("Overall outcome set to ${oo.name.toUpperCase()}");
    _overallOutcome = oo;
  }

  get description {
    return _overallOutcome.description;
  }

  get outcomeName => _overallOutcome.name;

  List<List<String>> get checkInTimeList {
    List<List<String>> citl = [];
    var keyList = _checkInTimeMap.keys.toList();
    keyList.sort();
    for (var ck in keyList) {
      citl.add([ck.toString(), _checkInTimeMap[ck]!.toUtc().toIso8601String()]);
    }
    return citl;
  }

// static Map<String, dynamic> toJson(EventOutcomes value) => {
//         'overall_outcome': value.outcomeName,
//         'check_in_times': value.checkInTimeList,
//       };
}
