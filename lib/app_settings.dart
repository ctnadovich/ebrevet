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

import 'package:ebrevet_card/future_events.dart';
import 'package:ebrevet_card/mylogger.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'region.dart';
import 'region_data.dart';
import 'my_settings.dart';
// import 'permanent.dart';

class AppSettings {
  ////////////////////
  // Constant settings

  static const int infinity = 9999999;
  static const int infiniteDistance = infinity;
  static const int advanceStartTimeGraceMinutes = 60;
  static const int prerideTimeWindowDays = 15;
  static const int prerideDisallowHours = 24;
  static const int httpGetTimeoutSeconds = 30;
  static const int timeRefreshPeriod = 60;
  static const int gpsRefreshPeriodDefault = 20;
  static const int maxRUSAID = infinity;
  static const int maxACPCODE = infinity;
  static const int maxPERMID = infinity;
  // static const bool autoFirstControlCheckIn = true;
  static const double defaultProximityRadius = 500.0; // meters

  //////////
  // Secrets

  static String get magicStartCode => RegionData.magicStartCode;
  static String get magicRUSAID => RegionData.magicRUSAID;

  //////////
  // Filenames
  static const String futureEventsFilename =
      'futureEvents.json'; // File to save events locally
  static const String pastEventsFileName = 'pastEvents.json';
  static const String storedRegionsFilename =
      'regions.json'; // File to save regions locally

  ////////////////////////
  // Package Info Settings

  static String? appName;
  static String? packageName;
  static String? version;
  static String? buildNumber;

  static Future<void> initializePackageInfo() async {
    MyLogger.entry('Init package info start');
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
    MyLogger.entry('Init package info end');
  }

  //////////////////////////////
  // Persistent Settings
  //
  // Basic ID

  static MySetting<String> firstName = MySetting<String>(
      key: 'key-first-name',
      defaultValue: '',
      title: 'First Name',
      validator: notEmptyValidator,
      icon: const Icon(Icons.person));

  static MySetting<String> lastName = MySetting<String>(
      key: 'key-last-name',
      defaultValue: '',
      title: 'Last Name',
      validator: notEmptyValidator,
      icon: const Icon(Icons.person));

  static MySetting<String> rusaID = MySetting<String>(
    key: 'key-rusa-id',
    defaultValue: '',
    title: 'Rider ID',
    validator: numericIDValidator,
    icon: const Icon(Icons.numbers),
  );

  // Event Info

  static MySetting<int> regionID = MySetting<int>(
    key: 'key-region-id',
    defaultValue: Region.defaultRegion,
    title: FutureEventsSourceID.fromRegion.description,
    validator: numericIDValidator,
    icon: const Icon(Icons.map),
  );

  // static MySetting<String> permSearchLocation = MySetting<String>(
  //   key: 'key-perm-search-location',
  //   defaultValue: Permanent.defaultSearch,
  //   title: '${FutureEventsSourceID.fromPerm.description} Location',
  //   validator: notEmptyValidator,
  //   icon: const Icon(Icons.map),
  // );

  // static MySetting<double> permSearchRadius = MySetting<double>(
  //   key: 'key-perm-search-radius',
  //   defaultValue: 50,
  //   title: '${FutureEventsSourceID.fromPerm.description} Radius (mi)',
  //   validator: doubleValidator,
  //   icon: const Icon(Icons.map),
  // );

  static MySetting<String> eventInfoURL = MySetting<String>(
    key: 'key-event-info-url',
    defaultValue: '',
    title: FutureEventsSourceID.fromURL.description,
    validator: urlFieldValidator,
    icon: const Icon(Icons.web_asset),
  );

  static MySetting<FutureEventsSourceID> futureEventsSourceID =
      MySetting<FutureEventsSourceID>(
          key: 'key-event-info-source-id',
          defaultValue: FutureEventsSourceID.fromRegion,
          title: 'Event Information Source');

  // Other
  static MySetting<Color> themeColor = MySetting(
      key: 'key-theme-color', defaultValue: Colors.blue, title: 'Theme Color');

  // Preferences

  static MySetting<int> gpsRefreshPeriod = MySetting(
    key: 'key-gps-refresh-period',
    defaultValue: gpsRefreshPeriodDefault,
    title: 'GPS Refresh Seconds',
    validator: gpsRefreshValidator,
    icon: const Icon(Icons.watch),
  );

  static MySetting<bool> allowCheckinComment = MySetting(
    key: 'key-allow-checkin-comment',
    defaultValue: true,
    title: 'Allow CheckIn Comment',
    icon: const Icon(Icons.comment),
  );

  // Advanced Developer

  static MySetting<double> proximityRadius = MySetting(
    key: 'key-control-proximity-threshold',
    defaultValue: defaultProximityRadius,
    title: 'Control Proximity Radius',
    validator: doubleValidator,
    icon: const Icon(Icons.radar),
  );

  static MySetting<bool> openTimeOverride = MySetting(
    key: 'key-open-time-override',
    defaultValue: false,
    title: 'Open Time Override',
    icon: const Icon(Icons.settings),
  );

  static MySetting<bool> controlProximityOverride = MySetting(
      key: 'key-control-proximity-override',
      defaultValue: false,
      title: 'Control Proximity Override',
      icon: const Icon(Icons.settings));

  static MySetting<bool> canDeletePastEvents = MySetting(
      key: 'key-delete-past-events',
      defaultValue: false,
      title: 'Can Delete Past Events',
      icon: const Icon(Icons.settings));

  static MySetting<bool> canCheckInLate = MySetting(
      key: 'key-check-in-late',
      defaultValue: true,
      title: 'Can Check In Late to Controls',
      icon: const Icon(Icons.settings));

  static MySetting<bool> prerideDateWindowOverride = MySetting(
      key: 'key-preride-date-window-override',
      defaultValue: false,
      title: 'Pre-ride Date Window Override',
      icon: const Icon(Icons.settings));

  //static iinitializeMySettings() {
  // eventInfoSource = MySetting<EventInfoSource>(
  //     key: 'key-event-info-source',
  //     defaultValue: EventInfoSource.rusaRegion,
  //     title: 'Event Info Source');

  // }

  ///////////////////
  // Sugared Settings

  static String get fullName => "${firstName.value} ${lastName.value}";

  static bool get isRusaIDSet => rusaID.value.isNotEmpty;

  static bool get areRequiredSettingsSet =>
      rusaID.value.isNotEmpty &&
      (firstName.value.isNotEmpty || lastName.value.isNotEmpty);

  static bool get isMagicRusaID => rusaID.value.trim() == magicRUSAID.trim();

  //////////////
  // Validators

  static String? notEmptyValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter something';
    } else {
      return null;
    }
  }

  static String? urlFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter something';
    }
    if (false == Uri.parse(value).host.isNotEmpty) {
      return 'Invalid URL';
    } else {
      return null;
    }
  }

  static String? numericIDValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a numeric ID';
    }
    if (false == isValidNumericID(value)) return 'Invalid numeric ID';
    return null;
  }

  static String? gpsRefreshValidator(String? value) {
    int minVal = 1;
    int maxVal = 60;
    if (value == null || value.isEmpty) {
      return 'Please enter between $minVal and $maxVal seconds';
    }
    if (false == isValidNumericID(value, minValue: minVal, maxValue: maxVal)) {
      return 'Must be between $minVal and $maxVal seconds';
    }
    return null;
  }

  static String? doubleValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a decimal number';
    }
    if (false == isPositiveReal(value)) return 'Not a positive real number';
    return null;
  }

  static bool isValidNumericID(String? value,
      {int maxValue = infinity, int minValue = 1}) {
    if (value == null) return false;
    final numericID = num.tryParse(value);
    if (numericID == null ||
        numericID is! int ||
        numericID < minValue ||
        numericID > maxValue) {
      return false;
    }
    return true;
  }

  static bool isPositiveReal(String? value) {
    if (value == null) return false;
    final numericID = double.tryParse(value);
    if (numericID == null || numericID < 0) {
      return false;
    }
    return true;
  }
}
