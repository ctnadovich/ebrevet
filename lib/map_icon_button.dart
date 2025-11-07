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

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapIconButton extends StatelessWidget {
  final double latitude;
  final double longitude;

  const MapIconButton({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  Future<void> _openMap() async {
    final Uri googleUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (!await launchUrl(googleUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $googleUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.map, color: Colors.blue),
      tooltip: 'Open in Maps',
      onPressed: _openMap,
    );
  }
}
