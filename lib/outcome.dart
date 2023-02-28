
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

enum OverallOutcome {
  dns,
  dnf,
  dnq,
  finish,
  active,
  unknown;

  static Map _description = {
    dns: 'Not Started',
    dnf: 'Did Not Finish',
    dnq: 'Disqualified',
    finish: 'Finished',
    active: 'Riding Now',
    unknown: 'Unknown',
  };

  get description => _description[this];
}

// The plural (outcomeS versus outcome) refers to the multiple outcomes within a single event -- overall and control times

class EventOutcomes {
  OverallOutcome _overallOutcome = OverallOutcome.dns;
  Map<int, DateTime> _checkInTimeMap = {}; // control number -> check in time
  late final bool _preRideMode;

  EventOutcomes({OverallOutcome? oo, Map<int, DateTime>? checkInTimeMap, bool? preRideMode}){
    _checkInTimeMap=checkInTimeMap ?? {};
    _overallOutcome=oo ?? OverallOutcome.dns;
    _preRideMode = preRideMode??false;
  }

  Map<String, dynamic> get toMap =>
  {
    'overall_outcome': _overallOutcome.name,
    'pre_ride': _preRideMode,
    'check_in_times': _checkInTimeMap.map((key, value) => MapEntry(key.toString(), value.toUtc().toIso8601String())),
  };

  EventOutcomes.fromMap(Map<String,dynamic>jsonMap){
    _overallOutcome=OverallOutcome.values.byName(jsonMap['overall_outcome']);
    _preRideMode=jsonMap['pre_ride'] ?? false;
    Map <String, dynamic> checkInJsonMap=jsonMap['check_in_times'];
    _checkInTimeMap.clear();  // not needed as default constructor will make this empty anyway
    for (var k in checkInJsonMap.keys){
      int kInt = int.parse(k);
      DateTime vDateTime = DateTime.parse(checkInJsonMap[k]);
      _checkInTimeMap[kInt]=vDateTime;
    }
    // =checkInJsonMap.map((key, value) => MapEntry(int.parse(key), DateTime.parse(value)));
  }

  // When using this setter, don't forget to call EventHistory.save() afterwards

  void setControlCheckInTime(int controlKey, DateTime t) {
    _checkInTimeMap[controlKey] = t;
  }

  DateTime? getControlCheckInTime(int controlKey){
    return _checkInTimeMap[controlKey];
  }

  OverallOutcome get overallOutcome {
    return _overallOutcome;
  }

  // When using this setter, don't forget to call EventHistory.save() afterwards

  set overallOutcome(OverallOutcome oo) {
    print ("Overall outcome set to ${oo.name.toUpperCase()}");
    _overallOutcome = oo;
  }

bool get wasPreRide {return _preRideMode;}

  get description {
    return _overallOutcome.description;
  }

  get outcomeName => _overallOutcome.name;

  get checkInTimeList {
    List<List<String>> citl = [];
    var keyList = _checkInTimeMap.keys.toList();
    keyList.sort();
    for (var ck in keyList) {
      citl.add([ck.toString(), _checkInTimeMap[ck]!.toUtc().toIso8601String()]);
    }
    return citl;
  }

  static Map<String, dynamic> toJson(EventOutcomes value) => {
        'overall_outcome': value.outcomeName,
        'check_in_times': value.checkInTimeList,
      };
}
