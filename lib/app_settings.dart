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

import 'package:ebrevet_card/mylogger.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'region.dart';
import 'region_data.dart';
import 'my_settings.dart';

enum EventInfoSource {
  rusaRegion,
  rusaPerm,
  clubACPCode,
  eventInfoURL;

  static Map<EventInfoSource, String> descriptionMap = {
    rusaRegion: 'RUSA Region',
    rusaPerm: 'Permanent ID Number',
    clubACPCode: 'Club ACP Code',
    eventInfoURL: 'Event Info URL',
  };

  String get description => descriptionMap[this]!;
}

class AppSettings {
  ////////////////////
  // Constant settings

  static const int infiniteDistance = 9999999;
  static const int startableTimeWindowMinutes = 60;
  static const int prerideTimeWindowDays = 15;
  static const int httpGetTimeoutSeconds = 30;
  static const int timeRefreshPeriod = 60;
  static const int gpsRefreshPeriod = 20;
  static const int maxRUSAID = 999999;
  static const int maxACPCODE = 999999;
  static const int maxPERMID = 9999;
  static const bool autoFirstControlCheckIn = true;
  static const double defaultProximityRadius = 500.0; // meters

  //////////
  // Secrets

  static String get magicStartCode => RegionData.magicStartCode;
  static String get magicRUSAID => RegionData.magicRUSAID;

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
  // Persistent Settings getters

  // Basic ID
  static late MySetting<String> firstName;
  static late MySetting<String> lastName;
  static late MySetting<String> rusaID;

  // Event Info
  static late MySetting<Enum> eventInfoSource;
  static late MySetting<int> regionID;
  static late MySetting<String> eventInfoURL;

  // Other
  static late MySetting<Color> themeColor;

  // Advanced

  static late MySetting<double> proximityRadius;
  static late MySetting<bool> openTimeOverride;
  static late MySetting<bool> controlProximityOverride;
  static late MySetting<bool> canDeletePastEvents;
  static late MySetting<bool> prerideDateWindowOverride;

  static initializeMySettings() {
    firstName = MySetting<String>(
        key: 'key-first-name', defaultValue: '', title: 'First Name');

    lastName = MySetting<String>(
        key: 'key-last-name', defaultValue: '', title: 'Last Name');

    rusaID = MySetting<String>(
        key: 'key-rusa-id', defaultValue: '', title: 'RUSA ID');

    eventInfoSource = MySetting<EventInfoSource>(
        key: 'key-event-info-source',
        defaultValue: EventInfoSource.rusaRegion,
        title: 'Event Info Source');
    regionID = MySetting<int>(
        key: 'key-region-id',
        defaultValue: Region.defaultRegion,
        title: 'ACP Club Code');

    var rgn = Region.fromSettings();
    var url = rgn.futureEventsURL;
    eventInfoURL = MySetting<String>(
        key: 'key-event-info-url',
        defaultValue: url,
        title: 'Future Event Info URL');

    themeColor = MySetting(
        key: 'key-theme-color',
        defaultValue: Colors.blue,
        title: 'Theme Color');

    proximityRadius = MySetting(
        key: 'key-control-proximity-threshold',
        defaultValue: defaultProximityRadius,
        title: 'Control Proximity Radius');
    openTimeOverride = MySetting(
        key: 'key-open-time-override',
        defaultValue: false,
        title: 'Open Time Override');
    controlProximityOverride = MySetting(
        key: 'key-control-proximity-override',
        defaultValue: false,
        title: 'Control Proximity Override');
    canDeletePastEvents = MySetting(
        key: 'key-delete-past-events',
        defaultValue: false,
        title: 'Can Delete Past Events');
    prerideDateWindowOverride = MySetting(
        key: 'key-preride-date-window-override',
        defaultValue: false,
        title: 'Pre-ride Date Window Override');
  }

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

  static String? rusaFieldValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your RUSA ID';
    }
    if (false == isValidRusaID(value)) return 'Invalid RUSA ID';
    return null;
  }

  static String? rusaPermIDValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a Permanent ID';
    }
    if (false == isValidRusaID(value, maxValue: maxPERMID)) {
      return 'Invalid Permanent ID number';
    }
    return null;
  }

  static String? acpCodeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an ACP Club Code';
    }
    if (false == isValidRusaID(value, maxValue: maxACPCODE)) {
      return 'Invalid ACP Club Code';
    }
    return null;
  }

  static bool isValidRusaID(String? value, {int maxValue = maxRUSAID}) {
    if (value == null) return false;
    final rusaid = num.tryParse(value);
    if (rusaid == null || rusaid is! int || rusaid < 1 || rusaid > maxRUSAID) {
      return false;
    }
    return true;
  }
}
