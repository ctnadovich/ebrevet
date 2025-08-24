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
import 'package:another_flushbar/flushbar.dart';

// class OldSnackbarGlobal {
//   static GlobalKey<ScaffoldMessengerState> key =
//       GlobalKey<ScaffoldMessengerState>();

//   static void show(String message, {Color? color}) {
//     var themeColor = Theme.of(key.currentContext!).primaryColorDark;
//     MyLogger.entry("SnackBar: $message");
//     key.currentState!
//       ..hideCurrentSnackBar()
//       ..showSnackBar(SnackBar(
//         content: Container(
//             padding: const EdgeInsets.all(16),
//             // height: 100,
//             decoration: BoxDecoration(
//                 color: color ?? themeColor,
//                 borderRadius: const BorderRadius.all(Radius.circular(20.0))),
//             child: Column(
//               children: [
//                 Text(
//                   message,
//                   style: const TextStyle(fontSize: 16, color: Colors.white),
//                   textAlign: TextAlign.center,
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             )),
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 6),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ));
//   }
// }

/// Enhanced enum with all style info per type.
enum FlushbarStyle {
  info(),
  comment(
    position: FlushbarPosition.TOP,
    icon: Icons.comment,
    duration: Duration(seconds: 6), // override default
  ),
  error(
    icon: Icons.error,
  );

  final Duration duration;
  final FlushbarPosition position;
  final IconData icon;

  // Default values
  const FlushbarStyle({
    this.duration = const Duration(seconds: 3),
    this.position = FlushbarPosition.BOTTOM,
    this.icon = Icons.info,
  });
}

/// Entry in the flushbar queue.
class _FlushbarEntry {
  final String message;
  final FlushbarStyle style;

  _FlushbarEntry({required this.message, required this.style});
}

class SnackbarGlobal {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final List<_FlushbarEntry> _queue = [];
  static bool _isShowing = false;

  /// Call this to show a flushbar.
  static void show(String message, {FlushbarStyle style = FlushbarStyle.info}) {
    _queue.add(_FlushbarEntry(message: message, style: style));
    _tryShowNext();
  }

  static void _tryShowNext() {
    if (_isShowing || _queue.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null) {
      MyLogger.entry('No Context; Navigator not ready');
      return;
    } // Navigator not ready yet.

    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge
        ?.copyWith(color: theme.colorScheme.onSecondary);
    final backgroundColor = Theme.of(context).colorScheme.secondary;

    final entry = _queue.removeAt(0);
    _isShowing = true;

    Flushbar(
      // message: entry.message,
      messageText: Text(
        entry.message,
        style: textStyle,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: backgroundColor,
      icon: Icon(
        entry.style.icon,
        color: theme.colorScheme.onSecondary,
      ),
      duration: entry.style.duration,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
    ).show(context).then((_) {
      _isShowing = false;
      _tryShowNext(); // Show next in queue if any
    });
  }
}
