# ebrevet_card

An electronic brevet card for randonneuring.

## Introduction

This Android/iOS 
app serves as an automated brevet card that can provide Electronic Proof of Passage
on a randonneuring brevet, while maintaining some of the "feel" of the traditional paper brevet card process.  The app only needs to be activated at controls. If network access is available,
the app will report control check in times for the rider to a central server. 

## Features include

- Provides electronic proof of passage with a brevet card process requiring "check in" at controls.
- Needs network access initially to download event details, and finally to upload results. The app can be used effectively without continous Cellular service or Internet access.
- The phone can be turned off or rebooted and the app will continue to work. 
- Monitors distance to controls and open/close times, and only allows control check in when appropriate.
- Reports control check ins back to the region's web server to allow a real time rider progess page to be generated.
- Can be used by any club that implements support for downloading event details in JSON format
from their web site. 
- Pre-ride mode allows for "relative" control open/close times.
- Free, open source software.

## Randonneuring Resources:

- [Pennsylvania Randonneurs](https://parando.org)
- [Randonneurs USA](https://rusa.org)


## Developers

This application was developed in the Dart language using the Flutter framework. 

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

The code for this project is (C) 2023 Chris Nadovich released for public use under the GPLv3 
open source license. 

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

