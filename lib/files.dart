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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ebrevet_card/event_history.dart';
import 'package:path_provider/path_provider.dart';
import 'logger.dart';

class FileStorage {
  String fileName;

  FileStorage(this.fileName);

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  void clear() async {
    try {
      final file = await _localFile;
      await file.delete();
    } catch (e) {
      Logger.logInfo("In FileStorage.clear() Couldn't delete $fileName.");
    }
  }

  Future<Map<String, dynamic>> readJSON() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      var decodedResult = jsonDecode(contents) as Map<String, dynamic>;
      return decodedResult;
    } catch (e) {
      Logger.logInfo("Exception in FileStorage.readJSON: $e");
      return {};
    }
  }

  Future<bool> writeJSON(Map<String, dynamic> contents) async {
    try {
      final file = await _localFile;

      var jsonData = jsonEncode(contents,
          toEncodable: (Object? value) => (value is PastEvent)
              ? PastEvent.toJson(value)
              : throw FormatException('In FileStorage.writeJSON() Cannot convert to JSON: $value'
              ));

      await file.writeAsString(jsonData);


      Logger.logInfo("Wrote to file ${file.path}");
      return true;
    } catch (e) {
      Logger.logInfo("Failed write to file: $e");
      return false;
    }
  }
}
