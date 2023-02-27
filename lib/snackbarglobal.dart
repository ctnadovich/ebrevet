import 'package:flutter/material.dart';

class SnackbarGlobal {
  static GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  static void show(String message) {
    key.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(message))
          ); // TODO Better formatting, adjust timeout. Verify that standalone uses are true user viewable and not developer errors
  }
}
