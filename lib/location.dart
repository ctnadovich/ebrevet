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
// along with dogtag.  If not, see <http://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'control.dart';
import 'exception.dart';
import 'app_settings.dart';
import 'mylogger.dart';

class RiderLocation {
  static Position? riderLocation;
  static ValueNotifier <DateTime?> lastLocationUpdate = ValueNotifier(null);

  static bool gpsServiceEnabled = false;

  static void updateLocation() async {  // Consider automatic periodic report to remote server?  
                                        // of location not just when checiking in
                                        // Perhaps as settings option with different period
    try {
      var gpsServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (gpsServiceEnabled == false) {
        throw GPSException('GPS Service Not Enabled.');
      } else {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw GPSException('GPS permission refused.');
          }
        }
        riderLocation = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high)
            .timeout(const Duration(seconds: 5));
        lastLocationUpdate.value = DateTime.now();
        MyLogger.logInfo(
            'GPS Location updated at $lastLocationUpdateString was $latLongString');
      }
    } catch (e) {
      // SnackbarGlobal.show(e.toString());
      MyLogger.logInfo('GPS Error: ${e.toString()}');
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

  String get crowDistMetersString =>
      (crowDistMiles == null) ? '?' : crowDistMeters!.toStringAsFixed(1);
      
  String get crowCompassHeadingString =>
      (crowBearing == null) ? '?' : angleToCompassHeading(crowBearing);

  bool get isNearControl {
    if (crowDistMeters == null) return false;
    var d =  AppSettings.proximityRadius;
    var closeEnough = crowDistMeters! < d;
    return closeEnough;
  }

}
