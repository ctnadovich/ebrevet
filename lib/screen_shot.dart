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

import 'package:ebrevet_card/snackbarglobal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'mylogger.dart';

class ScreenShot {
  static void take(String filename, GlobalKey previewKey) async {
    try {
      if (previewKey.currentContext == null) {
        throw Exception("No context for preview Container");
      }
      RenderRepaintBoundary boundary = previewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      final directory = (await getApplicationDocumentsDirectory()).path;
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw const FormatException("Failed converting image to byte data.");
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();
      // print(pngBytes);
      File imgFile = File('$directory/$filename');
      imgFile.writeAsBytes(pngBytes);

      MyLogger.entry("Wrote image of ${pngBytes.length} bytes to $imgFile");

      /// Share Plugin
      await Share.shareXFiles([XFile(imgFile.path)]);
    } catch (e) {
      var message = "Failed to save screenshot: $e";
      FlushbarGlobal.show(message, style: FlushbarStyle.error);
      MyLogger.entry(message, severity: Severity.error);
    }
  }
}
