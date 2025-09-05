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
import 'package:confetti/confetti.dart';

enum FlushBarTextSize { small, medium, large }

/// Enhanced enum with all style info per type.
enum FlushbarStyle {
  info(),
  success(
    icon: Icons.emoji_events,
  ),
  comment(
    position: FlushbarPosition.TOP,
    icon: Icons.comment,
    textSize: FlushBarTextSize.medium,
    duration: Duration(seconds: 8), // override default
  ),
  error(
    icon: Icons.error,
  );

  final Duration duration;
  final FlushbarPosition position;
  final IconData icon;
  final FlushBarTextSize textSize;

  // Default values
  const FlushbarStyle({
    this.duration = const Duration(seconds: 3),
    this.position = FlushbarPosition.BOTTOM,
    this.icon = Icons.info,
    this.textSize = FlushBarTextSize.large,
  });
}

/// Entry in the flushbar queue.
class _FlushbarEntry {
  final String message;
  final FlushbarStyle style;

  _FlushbarEntry({required this.message, required this.style});
}

class FlushbarGlobal {
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
    }

    final theme = Theme.of(context);
    final entry = _queue.removeAt(0);
    _isShowing = true;

    // Base text style
    TextStyle? themeTextSize;

    switch (entry.style.textSize) {
      case FlushBarTextSize.small:
        themeTextSize = theme.textTheme.titleSmall;
        break;
      case FlushBarTextSize.medium:
        themeTextSize = theme.textTheme.titleMedium;
        break;
      case FlushBarTextSize.large:
        themeTextSize = theme.textTheme.titleLarge;
        break;
    }

    final textStyle =
        themeTextSize?.copyWith(color: theme.colorScheme.onSecondary);

    // Base background color
    final backgroundColor = theme.colorScheme.secondary;

    // Confetti controller for success
    ConfettiController? confettiController;
    Widget? flushbarContent;

    if (entry.style == FlushbarStyle.success) {
      confettiController =
          ConfettiController(duration: const Duration(seconds: 1));
      confettiController.play();

      flushbarContent = Stack(
        alignment: Alignment.center,
        children: [
          Text(
            entry.message,
            style: textStyle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          ConfettiWidget(
            confettiController: confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.orange,
              Colors.purple,
              Colors.yellow
            ],
          ),
        ],
      );
    } else {
      flushbarContent = Text(
        entry.message,
        style: textStyle,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    Flushbar(
      messageText: flushbarContent,
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
      confettiController?.dispose();
      _tryShowNext(); // Show next in queue if any
    });
  }
}
