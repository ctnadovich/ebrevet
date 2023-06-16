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
import 'utility.dart';

class ControlState extends ChangeNotifier {
  DateTime? _lastReportUpload;
  DateTime? _lastPositionUpdate;
  DateTime? _lastCheckIn;

  String get lastReportUploadString =>
      Utility.toBriefDateTimeString(_lastReportUpload);
  String get lastPositionUpdateString =>
      Utility.toBriefDateTimeString(_lastPositionUpdate);
  String get lastCheckInString => Utility.toBriefDateTimeString(_lastCheckIn);

  void reportUploaded() {
    _lastReportUpload = DateTime.now();
    notifyListeners();
  }

  void checkIn() {
    _lastCheckIn = DateTime.now();
    notifyListeners();
  }

  void positionUpdated() {
    _lastPositionUpdate = DateTime.now();
    notifyListeners();
  }

  void pastEventDeleted() {
    notifyListeners();
  }
}
