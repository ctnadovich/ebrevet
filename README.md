# eBrevet

![eBrevet](assets/images/eBrevet-128.png) 

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

<img src="https://parando.org/ebrevet/v19/ScreenShots/required_settings.png" width=33%/>

Once you've set your RUSA number and region, press "Continue". This will take
you to the main eBrevet screen. 

The main screen will show you future events for your selected Club/Region. The first time
you run the app, this page will be blank. If the page is blank, or it's been several days since the last time you updated the page, hit the "Refresh Events from Server" button. If you have Internet service, in a few seconds the available events from your chosen Club/Region will appear. 

**IMPORTANT:** *If your Club/Region changes the cues for an event (control location, start time, route, etc...), you will need to press "Refresh Events" again when you have Internet
access. If you don't do this, the event data on your phone may be invalid and you won't 
be able to ride.*

![eBrevet Screen Shots](https://parando.org/ebrevet/v19/ScreenShots/updating_events_process.png)

Once the latest future events are downloaded to your phone, you should see cards describing each
upcoming event. If the event may be pre-ridden, a "PRERIDE" button will appear on the lower right of the event card. On the scheduled day of the event a "RIDE" button will appear. Press this button to RIDE or PRERIDE the event. 

The first time you choose RIDE/PRERIDE, you will need to enter your Start Code to start the event. The start code is a four character code printed on your brevet card, and also is available from the event organizer. Every rider has a different start code.  If your Start Code isn't working, make sure you have
the latest version of the events Refreshed from the Server, and that you have the latest
version of the eBrevet app. 

Once you have started the event you need to check in to every control, including the start control. To be able to check in to a control, you need to be physically near the control and the time of day must be within the open/close interval of that control. When you are eligible to check in, a "Check In" button will appear. 

![eBrevet Screen Shots](https://parando.org/ebrevet/v19/ScreenShots/check_in_sequence.png)


After you check in, you will see either a orange three-dots icon, or a green check. The green check means you've checked in and your check-in time has been uploaded to the Club/Region. If you see an orange three-dots icon, that means the app itself has recorded your check-in, but your check-in has not been uploaded to the Club/Region yet. This will occur if your phone is in 
Airplane Mode or if there is no data service on your phone. At some point in the future when your phone has internet service again, press the "Upload Results" button and you should see all your orange marks turn into green checks. 

**IMPORTANT:** *Be sure all your controls show green checks at the end of the event. When all your controls are green you have officially completed the event and your results have been recorded at the Club/Region. If you still have some red marks next to controls, you need to find working Internet service and upload your results ASAP.*

<div style="text-align: center;">
<img src="https://parando.org/ebrevet/v19/ScreenShots/no_yes_upload.png" width=67%/>
</div>

While you are riding an event, you can hit the exit arrow on the upper left, returning 
to the main eBrevet Events page. To go back to riding and checking into controls, hit the CONTINUE RIDE button on the event card. Should you want to abandon an event, click the black X button next to the Riding Now indicator. It's possible to "Un-abandon" by hitting "RIDE" again. 

On the main eBrevet page you will see three horizontal lines in the upper left corner (the so called hamburger icon). Clicking this will open the side drawer menu. 

After your complete an event, the results will be visible on the "Past Events" page accessible from the drawer menu. Past events are stored on your phone. Should the app be uninstalled, Past Events will be erased. Of course, your results are also stored in Le Grand Livre for posterity, so no worries. 

![eBrevet Screen Shots](https://parando.org/ebrevet/v19/ScreenShots/finish_sequence.png)


## Club/Region Webserver Support

In order to support the eBrevet app for your Club/Region/Organization, you will need to configure your webserver to provide event details in JSON format on a public URL, and to accept JSON formatted results on
another URL. Send these two URLs to the eBrevet author and your URL will be compiled into the next version of eBrevet. 

The event details provided in JSON format by the Club/Region server must contain several requierd fields, including the name of the event, the start location, start date/time, and a list of control locations with open/close times. All times are ISO 8601 timestamps in UTC. All locations are RWGPS compatibile decimal N Lattitude and E Longitude. Distances in decimal miles. 

The JSON record can be produced in a variety of ways, including manually, cutting and pasting it from the RWGPS route and other data. Alternatively, the required information can be extracted automatically from the RWGPS data by means of a computer program. If your club uses RWGPS cue markup as described in 
the [Cue Wizard](https://parando.org/cue_wizard.html) system, or similar, automatic control info extraction is facilitated. See the Cue Wizard source code for example methods that are free to copy and use. 

However generated, the future event details must be provided as a JSON encoded list of events on a URL of the form 

```
https://<yourdomain.com/your_base_path>/future_events
```

An example of the JSON data that must be returned for future_events is show [in this file](examples/future_events.json).

When riders check into a control, if internet is available the eBrevet app will attempt to POST a JSON checkin record to a different URL of the form 

```
https://<yourdomain.com/your_base_path>/post_checkin
```

The checkin record will include all control checkins that have occured up to the current time, every time. The server should record the first checkin for each control and is free to ignore the rest. 

The checkin will also include an overall outcome determination that will say "finish" when all the controls have been checked, otherwise it will say "active" if the rider is still riding, or "dnf" or "dnq" if the rider has failed to complete the brevet. 

An example of the checkin record is the following

```
{"event_id":"938017-382","rider_id":"5456","control_index":"0","comment":"No Comment","outcome":{"overall_outcome":"active","check_in_times":[["0","2023-03-14T06:11:51.232885Z"]]},"app_version":"0.1.6","proximity_radius":9999999.0,"open_override":"YES","preride":"YES","rider_location":"37.4226711N, -122.0849872E","last_loc_update":"2023-03-14T06:11:07.902975Z","timestamp":"2023-03-14T06:11:51.235675Z","signature":"C37D730E"}
```

If the received checkin record is decoded successfully by the Club/Region server, and
the signature is valid, the sever should reply with a JSON acknowledgement that includes `"status";"OK"` and minimally
looks like this 

```
{"status":"OK","event_id":"938017-382","rider_id":"5456"}
```

Additionally, the Club/Region server can internally record and display checkin information as desired on their website.

Explanations of the checkin fields are as follows:

- `event_id` A unique string that identifies the event. It must be unique worldwide making it impossible for there to ever be two events with the same ID. Recommended is to use the ACP club code and the club-specific unique event ID separated by
a dash. 

- `rider_id` The rider's RUSA ID number

- `control_index` If the rider is currently checking in to a control, this field will appear giving the control number corresponding to the numbering used in the future_events control list for this control. If a rider is not at a control, this field will be absent. 

- `comment` A text comment provided by the rider

- `outcome` A map that contains the `overall_outcome` and a list of `check_in_times`. The `overall_outcome` can be active, dnf, dnq, or finish. The check ins are a list  of pairs, giving the `control_index` and UTC time of the check_in.

- Several other fields are given that add auxiliary information to the checkin that can
be useful to record/display. These include indications whether the ride is a pre-ride, and whether any "overrides" were used to waive proximity or open/close requiredments. 

- `app_version` The version of the eBrevet app. 

- `timestamp` ISO 8601 current time in UTC

- `signature` the first 8 hex digits of the SHA256 hash of a plaintext string. The plaintext is 
the timestamp, the event ID, the rider ID, and a club/region secret separated by dashes. The Club/Region webserver should reject checkin records that do not bear a correct signature. This prevents "spoofing" results into the server as well as general exploitation of the URL. 

The brevet start code is similar to the signature. 
The start code is the first 4 
hex digits of the SHA256 hash
of plaintext comprising the cue version, the event ID, the rider RUSA ID, and the 
club/region secret separated by dashes. In the hex result, 
a "X" is substituted for the digit "0" and
a "Y" is substituted for the digit "1" to avoid confusion with "O" and "I". Start code
comparisons should be case insensitive. 

## Randonneuring Resources:

- [Pennsylvania Randonneurs](https://parando.org)
- [Randonneurs USA](https://rusa.org)


## Developers

This application was developed in the Dart language using the Flutter framework. 

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

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

