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

// import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:ebrevet_card/app_settings.dart';

import 'region_data.dart';

// RegionData is stored separately to protect secrets
// Example here:
//
// class RegionData {
//   static const int defaultRegion = 938017;
//   static const magicStartCode = "secret code";
//
//   static Map<int, Map<String, String>> regionMap = {
//
//     YourACPClubCodeAsIntegerHere: {
//       'clubName': 'Your Club Name',
//       'regionName': 'Your Region Name',
//       'event_url': 'your url for fetching event JSON goes here',
//       'secret': 'your secret goes here',
//     },
//
//     -- More Regions go Here --
//
//   };
// }

class Region {
  late int regionID;
  late String clubName;
  late String regionName;
  late String eventURL;
  late String secret;

  Region({int regionID = RegionData.defaultRegion}) {
    int rid = (regionMap.containsKey(regionID)) ? regionID : defaultRegion;
    clubName = regionMap[rid]!['clubName']!;
    regionName = regionMap[rid]!['regionName']!;
    eventURL = regionMap[rid]!['event_url']!;
    secret = regionMap[rid]!['secret']!;
    regionID = rid;
  }

  // static get isSet {
  //   var rgnKey = AppSettings.regionID;
  //   return (rgnKey<1) ? false : true;
  // }

  Region.fromSettings() : this(regionID: AppSettings.regionID);

  static get regionMap => RegionData.regionMap;
  static get defaultRegion => RegionData.defaultRegion;
}
