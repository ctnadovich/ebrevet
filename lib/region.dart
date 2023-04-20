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
import 'region_data.dart';

// RegionData is stored separately to protect secrets
// Example here:
//
// class RegionData {
//  static const String magicRUSAID = '9999';
//  static const String magicStartCode = "XXXX";
//  static const String defaultSecret = 'foobarbaz'; // secret if not set by region
//  static const Map<int, String> regionSecret = {
//    938017: 'bizzbuzz',  // set for specific region
//
//     -- More region secrets go Here --
//
//  };
// }
//
//
//   };
// }

class Region {
  static const int defaultRegion = 938017; // PA Rando
  static const String defaultEbrevetBaseURL =
      "https://randonneuring.org/ebrevet";

  late int regionID;
  late String clubName;
  late String websiteURL;
  late String secret;
  late String regionSubName;
  late String stateCode;
  late String stateName;
  late String _ebrevetServerURL;

  Region({this.regionID = defaultRegion}) {
    int rid = (regionMap.containsKey(regionID)) ? regionID : defaultRegion;
    regionID = rid;

    // all these keys must be defined in the regionMap for every region
    clubName = regionMap[rid]!['club_name']!;
    regionSubName = regionMap[rid]!['region_name']!;
    stateCode = regionMap[rid]!['state_code']!;
    stateName = regionMap[rid]!['state_name']!;
    websiteURL = regionMap[rid]!['website_url']!;

    // region secrets are stored in RegionData
    secret = RegionData.regionSecret[rid] ?? RegionData.defaultSecret;

    // If a region specifies a server URL, use it verbatim.
    // Otherwise create it from a default basename and region ID
    _ebrevetServerURL = regionMap[rid]!['ebrevet_url'] ?? defaultEbrevetBaseURL;
  }

  String get regionName => "$regionSubName $stateName";

  // getters that add ebrevet function suffixes and
  // regionID parameter

  String get futureEventsURL =>
      "$_ebrevetServerURL/future_events/${regionID.toString()}";

  // This should be overriden by checkin_post_url from future_events data

  // String get fallbackCheckInURL =>
  //    "$_ebrevetServerURL/post_checkin/${regionID.toString()}";

  factory Region.fromSettings() {
    var rid = AppSettings.regionID.value;
    return Region(regionID: rid as int);
  }

  static const Map<int, Map<String, String>> regionMap = {
    902007: {
      'state_code': 'AK',
      'state_name': 'Alaska',
      'region_name': 'Anchorage',
      'club_name': 'Denali Randonneurs',
      'website_url': 'http://www.denalirandonneurs.com/',
    },
    901004: {
      'state_code': 'AL',
      'state_name': 'Alabama',
      'region_name': 'Birmingham',
      'club_name': 'Alabama Randonneurs',
      'website_url': 'http://www.mgmbikeclub.org/AlabamaRando',
    },
    903020: {
      'state_code': 'AZ',
      'state_name': 'Arizona',
      'region_name': 'Phoenix',
      'club_name': 'Arizona Randonneurs',
      'website_url': 'http://www.azbrevet.com',
    },
    905014: {
      'state_code': 'CA',
      'state_name': 'California',
      'region_name': 'Davis',
      'club_name': 'Davis Bike Club',
      'website_url':
          'https://www.davisbikeclub.org/ultra-distance-brevets-and-randonneuring',
    },
    905176: {
      'state_code': 'CA',
      'state_name': 'California',
      'region_name': 'Humboldt',
      'club_name': 'Humboldt Randonneurs',
      'website_url': 'http://www.humboldtrandonneurs.com/',
    },
    905051: {
      'state_code': 'CA',
      'state_name': 'California',
      'region_name': 'Los Angeles',
      'club_name': 'Pacific Coast Highway Randonneurs',
      'website_url': 'http://www.pchrandos.com',
    },
    905140: {
      'state_code': 'CA',
      'state_name': 'California',
      'region_name': 'San Diego',
      'club_name': 'San Diego Randonneurs',
      'website_url': 'https://sdrandos.sdrandos.com',
    },
    905030: {
      'state_code': 'CA',
      'state_name': 'California',
      'region_name': 'San Francisco',
      'club_name': 'San Francisco Randonneurs',
      'website_url': 'http://sfrandonneurs.org/',
    },
    905166: {
      'state_code': 'CA',
      'state_name': 'California',
      'region_name': 'San Luis Obispo',
      'club_name': 'San Luis Obispo Randonneurs',
      'website_url': 'http://slorandonneur.org/',
    },
    905106: {
      'state_code': 'CA',
      'state_name': 'California',
      'region_name': 'Santa Cruz',
      'club_name': 'Santa Cruz Randonneurs',
      'website_url': 'http://www.santacruzrandonneurs.org',
    },
    905171: {
      'state_code': 'CA',
      'state_name': 'California',
      'region_name': 'Santa Rosa',
      'club_name': 'Santa Rosa Randonneurs',
      'website_url': 'https://santarosarandos.org/',
    },
    906002: {
      'state_code': 'CO',
      'state_name': 'Colorado',
      'region_name': 'Boulder',
      'club_name': 'Rocky Mountain Cycling Club',
      'website_url': 'https://www.rmccrides.com/brevets.htm',
    },
    909062: {
      'state_code': 'FL',
      'state_name': 'Florida',
      'region_name': 'Central',
      'club_name': 'Central Florida Randonneurs',
      'website_url': 'http://floridarandonneurs.com/wordpress',
    },
    909034: {
      'state_code': 'FL',
      'state_name': 'Florida',
      'region_name': 'Northeast',
      'club_name': 'Northeast Florida Randonneurs',
      'website_url': 'http://www.cyclingforever.com/nefr.html',
    },
    909014: {
      'state_code': 'FL',
      'state_name': 'Florida',
      'region_name': 'Southern',
      'club_name': 'South Florida Randonneurs',
      'website_url': 'https://sflrando.weebly.com/',
    },
    910004: {
      'state_code': 'GA',
      'state_name': 'Georgia',
      'region_name': 'Atlanta',
      'club_name': 'Audax Atlanta',
      'website_url': 'http://www.audaxatlanta.com',
    },
    911003: {
      'state_code': 'HI',
      'state_name': 'Hawaii',
      'region_name': 'Maui',
      'club_name': 'Maui Randonneurs',
      'website_url': 'https://sites.google.com/view/mauirandonneurs',
    },
    915005: {
      'state_code': 'IA',
      'state_name': 'Iowa',
      'region_name': 'Central',
      'club_name': 'Iowa Randonneurs',
      'website_url': 'http://iowarandos.org/',
    },
    913005: {
      'state_code': 'IL',
      'state_name': 'Illinois',
      'region_name': 'Chicago',
      'club_name': 'Great Lakes Randonneurs',
      'website_url': 'http://www.glrrando.org/',
    },
    913042: {
      'state_code': 'IL',
      'state_name': 'Illinois',
      'region_name': 'Quad Cities',
      'club_name': 'Quad Cities Randonneurs',
      'website_url': 'https://www.qcrandonneurs.org',
    },
    914005: {
      'state_code': 'IN',
      'state_name': 'Indiana',
      'region_name': 'Indianapolis',
      'club_name': 'Indiana Randonneurs',
      'website_url': 'http://indyrando.ridestats.bike',
    },
    917002: {
      'state_code': 'KY',
      'state_name': 'Kentucky',
      'region_name': 'Louisville',
      'club_name': 'Louisville Bicycle Club',
      'website_url': 'http://www.louisvillebicycleclub.org/',
    },
    921005: {
      'state_code': 'MA',
      'state_name': 'Massachusetts',
      'region_name': 'Boston',
      'club_name': 'New England Randonneurs',
      'website_url': 'https://ner.bike',
    },
    921009: {
      'state_code': 'MA',
      'state_name': 'Massachusetts',
      'region_name': 'Westfield',
      'club_name': 'New Horizons Cycling Club',
      'website_url': 'http://www.GreatRiverRide.com',
    },
    946012: {
      'state_code': 'MD',
      'state_name': 'Virginia',
      'region_name': 'Capital Region',
      'club_name': 'DC Randonneurs',
      'website_url': 'http://www.dcrand.org/dcr/',
    },
    922015: {
      'state_code': 'MI',
      'state_name': 'Michigan',
      'region_name': 'Detroit',
      'club_name': 'Detroit Randonneurs',
      'website_url': 'http://detroitrandonneurs.org/',
    },
    923003: {
      'state_code': 'MN',
      'state_name': 'Minnesota',
      'region_name': 'Twin Cities / Rochester',
      'club_name': 'Minnesota Randonneurs',
      'website_url': 'http://www.mnrando.org/',
    },
    925005: {
      'state_code': 'MO',
      'state_name': 'Missouri',
      'region_name': 'Kansas City',
      'club_name': 'Audax Kansas City',
      'website_url': 'http://www.audaxkc.com/',
    },
    926001: {
      'state_code': 'MT',
      'state_name': 'Montana',
      'region_name': 'Bozeman',
      'club_name': 'Gallatin Valley Bicycle Club',
      'website_url': 'http://sites.google.com/site/montanarando/Home',
    },
    933011: {
      'state_code': 'NC',
      'state_name': 'North Carolina',
      'region_name': 'Asheville',
      'club_name': 'Asheville International Randonneurs',
      'website_url': 'https://air.bikeavl.com/',
    },
    933057: {
      'state_code': 'NC',
      'state_name': 'North Carolina',
      'region_name': 'High Point',
      'club_name': 'Bicycle For Life Club',
      'website_url': 'http://www.bicycleforlife.org/rusa/index.html',
    },
    933045: {
      'state_code': 'NC',
      'state_name': 'North Carolina',
      'region_name': 'Raleigh',
      'club_name': 'North Carolina Bicycle Club',
      'website_url': 'https://raleighrando.web.unc.edu/',
    },
    927005: {
      'state_code': 'NE',
      'state_name': 'Nebraska',
      'region_name': 'Omaha',
      'club_name': 'Nebraska Sandhills Randonneurs',
      'website_url': 'http://www.nebraskasandhillsrandonneurs.com',
    },
    930029: {
      'state_code': 'NJ',
      'state_name': 'New Jersey',
      'region_name': 'NYC and Princeton',
      'club_name': 'New Jersey Randonneurs',
      'website_url': 'http://www.njrandonneurs.org',
    },
    932007: {
      'state_code': 'NY',
      'state_name': 'New York',
      'region_name': 'Central/Western',
      'club_name': 'Finger Lakes Randonneurs',
      'website_url': 'http://www.distancerider.net',
    },
    932005: {
      'state_code': 'NY',
      'state_name': 'New York',
      'region_name': 'Long Island',
      'club_name': 'Long Island Randonneurs',
      'website_url': 'http://lirando.org',
    },
    935012: {
      'state_code': 'OH',
      'state_name': 'Ohio',
      'region_name': 'Columbus',
      'club_name': 'Ohio Randonneurs',
      'website_url': 'http://ohiorandonneurs.org',
    },
    936006: {
      'state_code': 'OK',
      'state_name': 'Oklahoma',
      'region_name': 'Norman',
      'club_name': 'Oklahoma Randonneurs',
      'website_url': 'https://www.facebook.com/groups/1514201805512796/',
    },
    937004: {
      'state_code': 'OR',
      'state_name': 'Oregon',
      'region_name': 'Eugene',
      'club_name': 'Willamette Randonneurs',
      'website_url': 'http://will-rando.org',
    },
    937020: {
      'state_code': 'OR',
      'state_name': 'Oregon',
      'region_name': 'Portland',
      'club_name': 'Oregon Randonneurs',
      'website_url': 'http://orrando.blogspot.com',
    },
    938017: {
      'state_code': 'PA',
      'state_name': 'Pennsylvania',
      'region_name': 'Eastern',
      'club_name': 'Pennsylvania Randonneurs',
      'website_url': 'http://www.parandonneurs.com',
    },
    938016: {
      'state_code': 'PA',
      'state_name': 'Pennsylvania',
      'region_name': 'Pittsburgh',
      'club_name': 'Western Pennsylvania Bicycle Club',
      'website_url': 'http://www.pittsburghrandonneurs.com',
    },
    941005: {
      'state_code': 'SD',
      'state_name': 'South Dakota',
      'region_name': 'Sioux Falls',
      'club_name': 'Falls Area Randonneurs',
      'website_url': 'https://fallsarearando.wordpress.com/',
    },
    942007: {
      'state_code': 'TN',
      'state_name': 'Tennessee',
      'region_name': 'Nashville',
      'club_name': 'Tennessee Randonneurs',
      'website_url': 'http://tnrandonneurs.org',
    },
    943025: {
      'state_code': 'TX',
      'state_name': 'Texas',
      'region_name': 'Austin',
      'club_name': 'Hill Country Randonneurs',
      'website_url': 'http://www.hillcountryrandonneurs.org',
    },
    943049: {
      'state_code': 'TX',
      'state_name': 'Texas',
      'region_name': 'Central Texas',
      'club_name': 'Heart of Texas Randonneurs',
      'website_url': 'http://Heartoftexasrandonneurs.org',
    },
    943026: {
      'state_code': 'TX',
      'state_name': 'Texas',
      'region_name': 'Dallas',
      'club_name': 'Lone Star Randonneurs',
      'website_url': 'http://www.lonestarrandon.org/',
    },
    943030: {
      'state_code': 'TX',
      'state_name': 'Texas',
      'region_name': 'Houston',
      'club_name': 'Houston Randonneurs',
      'website_url': 'http://www.houstonrandonneurs.org',
    },
    943003: {
      'state_code': 'TX',
      'state_name': 'Texas',
      'region_name': 'West Texas',
      'club_name': 'West Texas Randonneurs',
      'website_url': 'http://www.pbbatx.com//randonneuring/',
    },
    944008: {
      'state_code': 'UT',
      'state_name': 'Utah',
      'region_name': 'Salt Lake City',
      'club_name': 'Salt Lake Randonneurs',
      'website_url': 'http://www.SaltLakeRandos.org',
    },
    946020: {
      'state_code': 'VA',
      'state_name': 'Virginia',
      'region_name': 'Northern',
      'club_name': 'Northern Virginia Randonneurs',
      'website_url': 'http://www.cyclingforever.com/nvr.html',
    },
    946002: {
      'state_code': 'VA',
      'state_name': 'Virginia',
      'region_name': 'Tidewater',
      'club_name': 'Tidewater Randonneurs',
      'website_url': 'http://tidewaterrando.com/',
    },
    947018: {
      'state_code': 'WA',
      'state_name': 'Washington',
      'region_name': 'Seattle',
      'club_name': 'Seattle International Randonneurs',
      'website_url': 'http://www.seattlerandonneur.org',
    },
    949007: {
      'state_code': 'WI',
      'state_name': 'Wisconsin',
      'region_name': 'Western',
      'club_name': 'Driftless Randonneurs',
      'website_url': 'http://www.driftlessrandos.org',
    },
  };
}
