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

enum Severity{
  info,
  warning,
  error,
}

class LogRecord{
  late DateTime timestamp;
  Severity severity;
  String message;
  LogRecord(this.severity, this.message){
    timestamp=DateTime.now();
  }
}

class MyLogger {
  static List <LogRecord> log = [];

  static const int logLength = 100; 

  static void logInfo(String s){
    log.add(LogRecord(Severity.info, s));
    if(log.length>logLength) log.removeAt(0);
    print("${log.length}:$s");
  }
}