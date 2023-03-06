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

class NoPreviousDataException implements Exception {
  String message;
  NoPreviousDataException(this.message);
  @override
  String toString() => message;
}

class GPSException implements Exception {
  String message;
  GPSException(this.message);
  @override
  String toString() => "Is your GPS enabled? $message";
}

class ServerException implements Exception {
  String message;
  ServerException(this.message);
  @override
  String toString() => message;
}

class NoInternetException implements Exception {
  String message;
  Object? error;
  NoInternetException(this.message, {this.error});
  @override
  String toString() => "Is your Internet service off? $message";
}
