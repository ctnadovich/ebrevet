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

import 'package:flutter/foundation.dart'; // for VoidCallback
import 'dart:async';
import 'mylogger.dart';

class Ticker {
  static const int tickPeriod = 1;

  Timer? timer;
  int tTick = 0;

  init({int period = tickPeriod, VoidCallback? onTick}) {
    var tickDuration = const Duration(seconds: tickPeriod);

// DONE it's unclear why this periodTicks modulous is used
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
