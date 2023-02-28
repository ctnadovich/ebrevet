import 'package:flutter_settings_screens/flutter_settings_screens.dart';
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
//       'name': 'Your Region Name',
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
  late String name;
  late String eventURL;
  late String secret;

  static const String magicStartCode=RegionData.magicStartCode;

  Region({int r = RegionData.defaultRegion}) {
    int rid = (regionMap.containsKey(r)) ? r : defaultRegion;
    name = regionMap[rid]!['name']!;
    eventURL = regionMap[rid]!['event_url']!;
    secret = regionMap[rid]!['secret']!;
    regionID = rid;
  }

  static get isSet {
    var rgnKey = Settings.getValue<int>('key-region');
    return (rgnKey == null || rgnKey<1) ? false : true;
  }

  Region.fromSettings()
      : this(
            r: Settings.getValue<int>('key-region') ??
                RegionData.defaultRegion);

  static get regionMap => RegionData.regionMap;
  static get defaultRegion => RegionData.defaultRegion;
}
