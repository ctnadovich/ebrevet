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
import 'package:shared_preferences/shared_preferences.dart';
import 'utility.dart';

class MySetting<T> {
  final String key;
  final T defaultValue;
  final String title;
  final String? Function(String? value)? validator;
  final Icon? icon;
  final void Function()? onChanged;

  static final Map<String, dynamic> _settingMap = <String, MySetting>{};

  static late SharedPreferences prefs;

  static Future<void> initSharedPreferences() async {
    MyLogger.entry('prefs init start');
    prefs = await SharedPreferences.getInstance();
    MyLogger.entry('prefs init end');
  }

  factory MySetting({
    required String key,
    required T defaultValue,
    required String title,
    String? Function(String? value)? validator,
    void Function()? onChanged,
    Icon? icon,
  }) {
    if (_settingMap.containsKey(key)) {
      return _settingMap[key]!;
    } else {
      var setting = MySetting._generate(
          key, defaultValue, title, validator, onChanged, icon);
      _settingMap[key] = setting;
      // MyLogger.entry(
      //     'Added setting $key; Map now contains ${_settingMap.length} entries.');
      return setting;
    }
  }

  MySetting._generate(this.key, this.defaultValue, this.title, this.validator,
      this.onChanged, this.icon);

  @override
  String toString() {
    return this.value.toString();
  }

  T get value {
    var s = prefs.getString(key);
    if (s == null || s.isEmpty) return defaultValue;

    try {
      if (T == String) {
        return s as T;
      } else if (T == bool) {
        return s.contains('t') as T;
      } else if (T == int) {
        return int.parse(s) as T;
      } else if (T == double) {
        return double.parse(s) as T;
      } else if (T == Color) {
        return Utility.hexToColor(s) as T;
      } else if (T == FutureEventsSourceID) {
        var i = int.parse(s);
        return FutureEventsSourceID.values[i] as T;
      } else {
        throw TypeError();
      }
    } catch (e) {
      prefs.setString(key, '');
      MyLogger.entry('Error $e. Invalid data "$s" for key "$key" erased',
          severity: Severity.warning);
      return defaultValue;
    }
  }

// Perhaps values should be JSON encoded. THat gets rid of this case.
// Or I could make a bunch of child types, each with a setPrefs method.

  // setValue(T val) async {
  //   if (this.defaultValue is String) {
  //     await prefs.setString(key, val as String);
  //   } else if (this.defaultValue is bool) {
  //     await prefs.setBool(key, val as bool);
  //   } else if (this.defaultValue is int) {
  //     await prefs.setInt(key, val as int);
  //   } else if (this.defaultValue is double) {
  //     await prefs.setDouble(key, val as double);
  //   } else if (this.defaultValue is Color) {
  //     await prefs.setString(key, Utility.colorToHex(val as Color));
  //   } else if (this.defaultValue is Enum) {
  //     await prefs.setInt(key, (val as Enum).index);
  //   } else {
  //     throw Exception('No Implementation for setting MySetting type.');
  //   }
  // }

  setValue(T val) async {
    String s;
    if (this.defaultValue is Enum) {
      s = (val as Enum).index.toString();
    } else {
      s = val.toString();
    }
    MyLogger.entry('Setting $key to $s');
    await prefs.setString(key, s);
    this.onChanged?.call();
  }

  setValueFromString(String val) async {
    MyLogger.entry('Setting $key to $val');
    await prefs.setString(key, val);
  }

  static Future<void> clear() async {
    for (String k in _settingMap.keys) {
      MyLogger.entry('Clearing $k');
      await prefs.remove(k);
    }
  }
}
