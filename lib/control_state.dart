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

import 'package:flutter/material.dart';

class ControlState extends ChangeNotifier {
  DateTime? lastReportUpload;
  DateTime? lastPositionUpdate;

  void reportUploaded() {
    lastReportUpload = DateTime.now();
    notifyListeners();
  }

  void positionUpdated() {
    lastPositionUpdate = DateTime.now();
    notifyListeners();
  }

  String get lastReportUploadString => _toSimpleDateTime(lastReportUpload);
  String get lastPositionUpdateString => _toSimpleDateTime(lastPositionUpdate);

  // TODO maybe factor these sorts of things into a Utility class?

  String _toSimpleDateTime(DateTime? dt) {
    var timestamp = dt?.toLocal().toIso8601String();
    return timestamp == null
        ? 'Never'
        : '${timestamp.substring(5, 10)} ${timestamp.substring(11, 19)}';
  }
}
