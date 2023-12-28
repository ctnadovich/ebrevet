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
import 'mylogger.dart';

class Ticker {
  static const int tickPeriod = 1;

  Timer? timer;
  int tTick = 0;

  init({int period = tickPeriod, Function()? onTick}) {
    var tickDuration = const Duration(seconds: tickPeriod);

// TODO it's unclear why this periodTicks modulous is used
// as separate instances of ticker objects will use separate
// instance of timers.

    int periodTicks = period.toDouble() ~/ tickPeriod;

    MyLogger.entry(
        "Initializing ticker: TickPeriod=$tickPeriod, periodTicks=$periodTicks");

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
