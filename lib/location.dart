import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'snackbarglobal.dart';
import 'control.dart';

class RiderLocation {
  static Position? riderLocation;
  static ValueNotifier <DateTime?> lastLocationUpdate = ValueNotifier(null);

  static bool gpsServiceEnabled = false;

  static void updateLocation() async {  // TODO automatic periodic report to remote server?  
                                        // Perhaps as settings option with different period
    try {
      var gpsServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (gpsServiceEnabled == false) {
        throw Exception('GPS Service Not Enabled.');
      } else {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('GPS permission refused.');
          }
        }
        riderLocation = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high)
            .timeout(Duration(seconds: 5));
        lastLocationUpdate.value = DateTime.now();
        print(
            'GPS Location updated at $lastLocationUpdateString was $latLongString');
      }
    } catch (e) {
      SnackbarGlobal.show(e.toString());
      print('GPS Error: ${e.toString()}');
    }
  }

  static get latLongString {
    return '${(riderLocation != null) ? riderLocation!.latitude.toStringAsFixed(5) : '?'}N, '
        '${(riderLocation != null) ? riderLocation!.longitude.toStringAsFixed(5) : '?'}E';
  }
static get latLongFullString {
    return '${(riderLocation != null) ? riderLocation!.latitude.toString() : '?'}N, '
        '${(riderLocation != null) ? riderLocation!.longitude.toString() : '?'}E';
  }

  static get lastLocationUpdateString {
    return (lastLocationUpdate.value == null)
        ? 'Never'
        : (lastLocationUpdate.value.toString()).substring(11, 16);
  }

 static get lastLocationUpdateMinutesAgoString {
    if(lastLocationUpdate.value == null) return 'unknown';
    return DateTime.now().difference(lastLocationUpdate.value!).inMinutes.toString();
 }


static get lastLocationUpdateUTCString {
    return (lastLocationUpdate.value == null)
        ? 'Never'
        : (lastLocationUpdate.value!.toUtc().toIso8601String());
  }

  static get lastLocationUpdateTimeZoneName {
    return (lastLocationUpdate.value == null) ? '' : lastLocationUpdate.value!.timeZoneName;
  }
}

class ControlLocation {
  late double controlLatitude;
  late double controlLongitude;


  ControlLocation(Control c) {
    controlLatitude = c.lat;
    controlLongitude = c.long;
  }

  static const miPerMeter = 0.0006213712;

  bool get locationsDefined =>
      (RiderLocation.riderLocation) !=
      null;

  double? get crowDistMeters {
    return (locationsDefined)
        ? Geolocator.distanceBetween(
            RiderLocation.riderLocation!.latitude,
            RiderLocation.riderLocation!.longitude,
            controlLatitude,
            controlLongitude)
        : null;
  }

  double? get crowDistMiles {
    var m = crowDistMeters;
    return (m == null) ? null : m * miPerMeter;
  }

  double? get crowBearing {
    return (locationsDefined)
        ? Geolocator.bearingBetween(
            RiderLocation.riderLocation!.latitude,
            RiderLocation.riderLocation!.longitude,
            controlLatitude,
            controlLongitude)
        : null;
  }

  static const octant = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];

  String angleToCompassHeading(theta) {
    return octant[((8 * theta / 360.0) % 8).round()];
  }

  String get crowDistMiString =>
      (crowDistMiles == null) ? '?' : crowDistMiles!.toStringAsFixed(1);
  String get crowCompassHeadingString =>
      (crowBearing == null) ? '?' : angleToCompassHeading(crowBearing);

  bool get isNearControl =>
      (crowDistMeters != null && crowDistMeters! < controlAutoCheckInDistance);

  double get controlAutoCheckInDistance =>
      Settings.getValue<double>('key-control-distance-threshold',
          defaultValue: 500)!;

}
