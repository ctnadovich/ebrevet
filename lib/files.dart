import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ebrevet_card/event_history.dart';
import 'package:path_provider/path_provider.dart';

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
      print("In FileStorage.clear() Couldn't delete $fileName.");
    }
  }

  Future<Map<String, dynamic>> readJSON() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      var decodedResult = jsonDecode(contents) as Map<String, dynamic>;
      return decodedResult;
    } catch (e) {
      print("Exception in FileStorage.readJSON: $e");
      return {};
    }
  }

  Future<bool> writeJSON(Map<String, dynamic> contents) async {
    try {
      final file = await _localFile;

      var jsonData = jsonEncode(contents,
          toEncodable: (Object? value) => (value is PastEvent)
              ? PastEvent.toJson(value)
              : throw Exception('In FileStorage.writeJSON() Cannot convert to JSON: $value'
              ));

      await file.writeAsString(jsonData);


      print("Wrote to file ${file.path}");
      return true;
    } catch (e) {
      print("Failed write to file: $e");
      return false;
    }
  }
}
