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
//

import 'package:flutter/material.dart';
import 'dart:math';

class Utility {
  static String toBriefTimeString(DateTime? dt) {
    var timestamp = dt?.toLocal().toIso8601String();
    return timestamp == null ? 'Never' : timestamp.substring(11, 16);
  }

  static String toBriefDateString(DateTime? dt) {
    var timestamp = dt?.toLocal().toIso8601String();
    return timestamp == null ? 'Never' : timestamp.substring(5, 10);
  }

  static String toBriefDateTimeString(DateTime? dt) {
    var timestamp = dt?.toLocal().toIso8601String();
    return timestamp == null
        ? 'Never'
        : '${timestamp.substring(5, 10)} @ ${timestamp.substring(11, 16)}';
  }

  static String toYearDateTimeString(DateTime? dt) {
    var timestamp = dt?.toLocal().toIso8601String();
    return timestamp == null
        ? 'Never'
        : '${timestamp.substring(0, 10)} @ ${timestamp.substring(11, 16)}';
  }

  static String toStringAsFixed(
    double d, {
    int n = 1,
  }) {
    return (d.toStringAsFixed(2).endsWith('.000000000000'.substring(0, n)))
        ? d.toStringAsFixed(n)
        : d.toStringAsFixed(n);
  }

  static Color hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  static String colorToHexString(Color color) {
    final red = (color.r * 255).toInt().toRadixString(16).padLeft(2, '0');
    final green = (color.g * 255).toInt().toRadixString(16).padLeft(2, '0');
    final blue = (color.b * 255).toInt().toRadixString(16).padLeft(2, '0');
    final alpha = (color.a * 255).toInt().toRadixString(16).padLeft(2, '0');
    final hexString = '#$alpha$red$green$blue';

    return hexString.toUpperCase();
  }

  static Color increaseColorSaturation(Color color, double increment) {
    var hslColor = HSLColor.fromColor(color);
    var newValue = min(max(hslColor.saturation + increment, 0.0), 1.0);
    return hslColor.withSaturation(newValue).toColor();
  }

  static Color increaseColorLightness(Color color, double increment) {
    var hslColor = HSLColor.fromColor(color);
    var newValue = min(max(hslColor.lightness + increment, 0.0), 1.0);
    return hslColor.withLightness(newValue).toColor();
  }

  static Color increaseColorHue(Color color, double increment) {
    var hslColor = HSLColor.fromColor(color);
    var newValue = min(max(hslColor.lightness + increment, 0.0), 360.0);
    return hslColor.withHue(newValue).toColor();
  }
}
