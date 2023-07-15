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

class TimeTill {
  late DateTime t;
  late Duration d;
  late int days;
  late int hours;
  late int minutes;
  late int seconds;
  late String unit;
  late String interval;
  late String inn;
  late String ed;
  late String ago;
  late String s;

  TimeTill(this.t) {
    d = t.difference(DateTime.now());
    var dAbs = d.abs();
    days = dAbs.inDays;
    hours = dAbs.inHours;
    minutes = dAbs.inMinutes;
    seconds = dAbs.inSeconds;

    if (days > 0) {
      interval = days.toString();
      unit = 'day';
      s = (days == 1) ? '' : 's';
    } else if (hours > 0) {
      interval = Utility.toStringAsFixed(minutes / 60.0);
      unit = 'hr';
      if (interval == '1' || interval == '1.0') {
        s = '';
        interval = '1';
      } else {
        s = 's';
      }
    } else if (minutes >= 1) {
      interval = Utility.toStringAsFixed(seconds / 60.0, n: 0);
      unit = 'min';
      if (interval == '1' || interval == '1.0') {
        s = '';
        interval = '1';
      } else {
        s = 's';
      }
    } else {
      interval = 'less than 1 min';
      s = '';
      unit = '';
    }

    unit = unit + s;

    inn = (d.inMicroseconds >= 0) ? 'in ' : '';
    ed = (d.inMicroseconds >= 0) ? 's' : 'ed';
    ago = (d.inMicroseconds >= 0) ? '' : ' ago';
  }

  String get terseDateTime {
    if (t.toLocal().day != DateTime.now().toLocal().day) {
      return Utility.toBriefDateTimeString(t);
    } else {
      return Utility.toBriefTimeString(t);
    }
  }
}
