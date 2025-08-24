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

import 'package:http/http.dart' as http;
import 'dart:async';

import 'mylogger.dart';
import 'exception.dart';
import 'app_settings.dart';

Future<String> fetchResponseFromServer(String url) async {
  MyLogger.entry('Fetching data from $url');
  http.Response? response;

  try {
    response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: AppSettings.httpGetTimeoutSeconds));
  } on TimeoutException {
    throw ServerException(
        'No response from $url after (${AppSettings.httpGetTimeoutSeconds} sec timeout).');
  } catch (e) {
    throw NoInternetException('Network error: $e');
  }

  if (response.statusCode != 200) {
    throw ServerException(
        'Error response from $url (Status Code: ${response.statusCode})');
  } else {
    return (response.body);
  }
}
