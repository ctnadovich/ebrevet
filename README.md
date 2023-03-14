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

## Rider Instructions

Install the app on your phone from the Google Play or Apple App stores, as appropriate
for your phone. The name of the app is "ebrevet" with the bundle ID "com.nadovich.ebrevet". 

When you first open the app, you will need to enter your RUSA ID number. Please make sure you
do this correctly. If you enter the wrong RUSA number, you wll not be able to use
the app till this is corrected. 

Also when you open eBrevet for the first time, you will be able to select the Club/Region
for the events you want to ride. Only regions that have support for eBrevet will appear on
the selection list. You will only see events from the Club/Region you select.

Once you've set your RUSA number and region, press "Continue".

The main screen has buttons for Future, Current, and Past events. There's also a "Settings" gear icon on the lower left, and a day/night mode switch on the upper right. 

![eBrevet Screen Shots](https://parando.org/ebrevet/ScreenShots.png)

Press the "Future Events" button. The first time you visit that page there will be no events listed. Hit the "Refresh Events from Server" button. If you have Internet service, in a few
seconds the available events from your chosen Club/Region will appear. 

**IMPORTANT:** *If your Club/Region changes the cues for an event (control location, start time, route, etc...), you will need to press "Refresh Events" again when you have Internet
access. If you don't do this, the event data on your phone may be invalid and you won't 
be able to ride.*

Once the latest future events are downloaded to your phone, you should see cards describing each
upcoming event. If the event may be pre-ridden, a "PRERIDE" button will apper on the lower right of the event card. On the scheduled day of the event a "RIDE" button will appear. Press this button to RIDE or PRERIDE the event. 

The first time you choose RIDE/PRERIDE, you will need to enter your Start Code to start the event. The start code is a four character code printed on your brevet card, and also is available from the event organizer. Every rider has a different start code.  If your Start Code isn't working, make sure you have
the latest version of the events Refreshed from the Server, and that you have the latest
version of the eBrevet app. 

Once you have started the event you need to check in to every control, including the start control. To be able to check in to a control, you need to be physically near the control and the time of day must be within the open/close interval of that control. When you are eligable to check in, a "Check In" button will appear. 

After you check in, you will see either a red three-dots icon, or a green check. The green check means you've checked in and your check-in time has been uploaded to the Club/Region. If you see a red threee-dots icon, that means the app itself has recorded your check-in, but your check-in has not been uploaded to the Club/Region yet. This will occur if your phone is in 
Airplane Mode or if there is no data service on your phone. At some point in the future when your phone has internet service again, press the "Upload Results" button and you should see all your red marks turn into green checks. 

**IMPORTANT:** *Be sure all your controls show green checks at the end of the event. When all your controls are green you have officially completed the event and your results have been recorded at the Club/Region. If you still have some red marks next to controls, you need to find working Internet service and upload your results ASAP.*


While you are riding an event, you can hit the exit arrow on the upper left, returning 
to the Future Events page. To go back to riding and checking into controls, hit the Continue button on the event card. Should you want to abandon an event, click the black X button next to the Riding Now indicator. It's possible to "Un-abandon" by hitting "RIDE" again. 

After your complete an event, the results will be visible on the "Past Events" page accessible from the main menu. Past events are stored on your phone. Should the app be uninstalled, Past Events will be erased. Of course, your results are also stored in Le Grand Livre for posterity, so no worries. 

## Club/Region Webserver Support

In order to support the eBrevet app for your Club/Region/Organization, you will need to configure your webserver to provide event details on a public URL, and to accept results on
another URL. 

The event details required include the name of the event, the start location, start date/time, and a list of control locations with open/close times. All times are UTC. All locations are RWGPS compatibile Lattitude and Longitude. If your club uses RWGPS cue markup as described in 
the [Cue Wizard](https://parando.org/cue_wizard.html) system, or similar, the required information can readily be extracted automatically from the RWGPS data. See the Cue Wizard source code for example methods.

Future event details must be provided as a JSON encoded list of events on a URL of the form 

```https://<yourdomain.com/your_base_path>/future_events```

An example of the JSON data that must be returned for future_events is show [in this file](examples/future_events.json).

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

Copyright (C) 2023 Chris Nadovich
This file is part of eBrevet <https://github.com/ctnadovich/ebrevet>.

eBrevet is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

eBrevet is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with eBrevet.  If not, see <http://www.gnu.org/licenses/>.

