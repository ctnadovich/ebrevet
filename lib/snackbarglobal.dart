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

import 'dart:async';

import 'package:ebrevet_card/mylogger.dart';
import 'package:flutter/material.dart';

enum FlushBarTextSize { small, medium, large }

/// Local replacement so the existing enum structure stays almost unchanged.
enum FlushbarPosition { top, bottom }

/// Enhanced enum with all style info per type.
enum FlushbarStyle {
  info(),
  success(
    icon: Icons.emoji_events,
  ),
  comment(
    position: FlushbarPosition.top,
    icon: Icons.comment,
    textSize: FlushBarTextSize.medium,
    duration: Duration(seconds: 8),
  ),
  error(
    icon: Icons.error,
  );

  final Duration duration;
  final FlushbarPosition position;
  final IconData icon;
  final FlushBarTextSize textSize;

  const FlushbarStyle({
    this.duration = const Duration(seconds: 3),
    this.position = FlushbarPosition.bottom,
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

  static final List<_FlushbarEntry> _queue = <_FlushbarEntry>[];
  static bool _isShowing = false;

  static OverlayEntry? _overlayEntry;
  static Timer? _dismissTimer;

  /// Call this to show a flushbar.
  static void show(String message, {FlushbarStyle style = FlushbarStyle.info}) {
    _queue.add(_FlushbarEntry(message: message, style: style));
    _tryShowNext();
  }

  static void _tryShowNext() {
    if (_isShowing || _queue.isEmpty) return;

    final NavigatorState? navigatorState = navigatorKey.currentState;
    final OverlayState? overlayState = navigatorState?.overlay;
    final BuildContext? context = overlayState?.context;

    if (context == null || overlayState == null) {
      MyLogger.entry('No Context; Navigator/Overlay not ready');
      return;
    }

    final ThemeData theme = Theme.of(context);
    final _FlushbarEntry entry = _queue.removeAt(0);
    _isShowing = true;

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

    final TextStyle? textStyle =
        themeTextSize?.copyWith(color: theme.colorScheme.onSecondary);

    final Color backgroundColor = theme.colorScheme.secondary;

    _overlayEntry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        Alignment alignment;
        switch (entry.style.position) {
          case FlushbarPosition.top:
            alignment = Alignment.topCenter;
            break;
          case FlushbarPosition.bottom:
            alignment = Alignment.bottomCenter;
            break;
        }

        Widget flushbarContent;

        if (entry.style == FlushbarStyle.success) {
          flushbarContent = Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Text(
                entry.message,
                style: textStyle,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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

        return IgnorePointer(
          ignoring: true,
          child: SafeArea(
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _FlushbarToast(
                  icon: entry.style.icon,
                  iconColor: theme.colorScheme.onSecondary,
                  backgroundColor: backgroundColor,
                  child: flushbarContent,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);

    _dismissTimer = Timer(entry.style.duration, () {
      _removeCurrent();
    });
  }

  static void _removeCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    try {
      _overlayEntry?.remove();
    } catch (_) {
      // Ignore remove errors if overlay already disappeared.
    }

    _overlayEntry = null;
    _isShowing = false;
    _tryShowNext();
  }

  /// Optional convenience if you ever want to dismiss the current one early.
  static void dismissCurrent() {
    if (!_isShowing) return;
    _removeCurrent();
  }

  /// Optional cleanup helper.
  static void clearQueue() {
    _queue.clear();
  }
}

class _FlushbarToast extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Widget child;

  const _FlushbarToast({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.child,
  });

  @override
  State<_FlushbarToast> createState() => _FlushbarToastState();
}

class _FlushbarToastState extends State<_FlushbarToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  widget.icon,
                  color: widget.iconColor,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}










/* // Copyright (C) 2023 Chris Nadovich
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
    Widget? flushbarContent;

    if (entry.style == FlushbarStyle.success) {
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
      _tryShowNext(); // Show next in queue if any
    });
  }
}
 */