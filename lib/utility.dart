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
//

class Utility {
  static String toBriefDateTimeString(DateTime? dt) {
    var timestamp = dt?.toLocal().toIso8601String();
    return timestamp == null
        ? 'Never'
        : '${timestamp.substring(5, 10)} @ ${timestamp.substring(11, 16)}';
  }

  static String toYearDateTimeString(DateTime? dt) {
    var timestamp = dt?.toLocal().toIso8601String();
    return timestamp == null
        ? 'Never'
        : '${timestamp.substring(0, 10)} @ ${timestamp.substring(11, 16)}';
  }

  static String toBriefTimeString(DateTime? dt) {
    var timestamp = dt?.toLocal().toIso8601String();
    return timestamp == null ? 'Never' : timestamp.substring(11, 16);
  }

  static String toStringAsFixed(
    double d, {
    int n = 1,
  }) {
    return (d.toStringAsFixed(2).endsWith('.000000000000'.substring(0, n)))
        ? d.toStringAsFixed(n)
        : d.toStringAsFixed(n);
  }
}
