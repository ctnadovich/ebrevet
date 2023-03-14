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
import 'dart:async';

class Ticker {
  static const int tickPeriod = 10;

  Timer? timer;
  int tTick = 0;

  init({int period = tickPeriod, Function()? onTick}) {
    var tickDuration = const Duration(seconds: tickPeriod);

    int periodTicks = period.toDouble() ~/ tickPeriod;

    timer = Timer.periodic(tickDuration, (Timer t) {
      if (0 == tTick % periodTicks) {
        if (onTick != null) onTick();
      }
      tTick++;
    });
  }

  dispose() {
    timer?.cancel();
  }
}
