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
//

import 'package:flutter/material.dart';

class DayNight extends ChangeNotifier {
  ThemeMode _mode;
  Color _color;
  DayNight({ThemeMode mode = ThemeMode.light, Color color = Colors.blue})
      : _mode = mode,
        _color = color;
  ThemeMode get mode => _mode;

  ThemeData get themeData => (_mode == ThemeMode.light) ? dayTheme : nightTheme;

  get dayTheme => ThemeData(
        useMaterial3: true,
        // colorScheme: ColorScheme.light(),
        colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.light, seedColor: _color), //  Colors.blue),
      );

  get nightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark, seedColor: _color), //  Colors.blue),
      );

  Icon get icon =>
      Icon((_mode == ThemeMode.light) ? Icons.light_mode : Icons.dark_mode);
  void toggleMode() {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  set color(c) {
    _color = c;
    notifyListeners();
  }

  Color get color => _color;
}
