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

import 'package:ebrevet_card/app_settings.dart';

class Permanent {
  static const String permanentBaseURL =
      "https://randonneuring.org/ebrevet/rusaperm";
  static const String defaultSearch = '18042'; // Easton, PA
  String query;

  Permanent({required this.query});

  String get futureEventsURL => "$permanentBaseURL/$query";

  // This should be overriden by checkin_post_url from future_events data

  // String get fallbackCheckInURL =>
  //    "$_ebrevetServerURL/post_checkin/${regionID.toString()}";

  factory Permanent.fromSettings() {
    var q = AppSettings.permSearchLocation.value;
    return Permanent(query: q);
  }
}
