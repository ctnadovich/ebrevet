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

import 'utility.dart';

enum Severity {
  hidden,
  info,
  warning,
  error,
}

class LogRecord {
  late DateTime timestamp;
  Severity severity;
  String message;
  LogRecord(this.severity, this.message) {
    timestamp = DateTime.now();
  }
}

class MyLogger {
  static final List<LogRecord> _log = [];

  static const int logLength = 100;

  static List<String> get records {
    List<String> recordList = [];

    for (var r in _log) {
      var s =
          "${Utility.toBriefTimeString(r.timestamp)} ${r.severity.name.toUpperCase().padRight(7)} ${r.message}";
      recordList.add(s);
    }

    return recordList;
  }

  static void entry(String s, {Severity severity = Severity.info}) {
    if (severity != Severity.hidden) _log.add(LogRecord(severity, s));
    if (_log.length > logLength) _log.removeAt(0);
    // This is the only place print() is used -- in our logging framework.
    print("LOG: $s"); // ignore: avoid_print
  }
}
