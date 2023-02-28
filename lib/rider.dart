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

import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class Rider {
  static const int maxRUSAID = 99999;

  static bool isValidRusaID(String? value) {
    if (value == null) return false;
    final rusaid = num.tryParse(value);
    if (rusaid == null ||
        rusaid is! int ||
        rusaid < 1 ||
        rusaid > Rider.maxRUSAID) {
      return false;
    }
    return true;
  }

  final String firstName;
  final String lastName;
  final String rusaID; // Should this be int? Or, like event ID, does it need to
  // be string for extensibility?

  Rider(this.firstName, this.lastName, this.rusaID);

  static get isSet {
    var fn = Settings.getValue<String>('key-first-name');
    var ln = Settings.getValue<String>('key-last-name');
    var id = Settings.getValue<String>('key-rusa-id');

    return (fn == null ||
            fn.isEmpty ||
            ln == null ||
            ln.isEmpty ||
            id == null ||
            id.isEmpty ||
            !isValidRusaID(id))
        ? false
        : true;
  }

  Rider.fromSettings()
      : this(
          Settings.getValue<String>('key-first-name', defaultValue: 'Unknown')!,
          Settings.getValue<String>('key-last-name', defaultValue: '')!,
          Settings.getValue<String>('key-rusa-id', defaultValue: 'Not Set')!,
        );

  String get firstLast {
    return "$firstName $lastName";
  }

  String get firstLastRUSA {
    return "$firstName $lastName (RUSA# $rusaID)";
  }
}
