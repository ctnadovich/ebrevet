# eBrevet

![eBrevet](assets/images/eBrevet-128.png) 

An electronic brevet card for randonneuring.

## Introduction

This Android/iOS app serves as an automated brevet card that can
provide Electronic Proof of Passage on a randonneuring brevet or permanent, while
maintaining some of the "feel" of the traditional paper brevet card
process.  The app only needs to be activated at controls and does
not require Internet data service at controls. If network
access is available, the app will report control check in times for
the rider to a central server. When the event is completed succefully,
the app generates a unique Proof of Passage Certificate that is sharable
on social media. 

You can find the app on both the [Apple Store](https://www.apple.com/app-store/) and the [Google Play Store](https://play.google.com). Search for "eBrevet" by "CTNadovich".

## Features include

- Provides electronic proof of passage with a brevet card process requiring "check in" at controls.
- Monitors distance to controls with GPS and open/close times versus clock time.  
- Only allows control check in when near (~500m) a control, and the control is open.
- Does not require anything physically at controls (eg no QR code, volunteer, etc... needed)
- Does not require any third party service (eg no Strava, Spot, RWGPS, Garmin... needed)
- Does not require photographs or any other media or service result to be reviewed by the organizer
- Pre-ride / permanent / and free-start modes allows "free" start-time and  "relative" control open/close times.
- Mass start mode allows flexible checkin time with evenyone "starting" at the offical start time.
- The app can be used effectively during an event without  Cellular service or Internet access.
- The phone can be turned off or rebooted and the app will continue to work correctly. 
- Low power use. Does not run in background. 
- Secure. Needs location permission only. Minimal use of personal information.
- Needs network access initially to download event details, and finally to upload results. 
- Requires a "start code" so riders must be registerd for event to use the app
- Check-in signature "codes" available for your paper brevet card as backup proof of passage.
- Finish certificate sharable on social media with unique "finish code" proof of passage.
- Reports control check ins back to server allowing rider progess monitoring.
- Can be used by any club publishing event details in specified JSON format. 
- Free, open source software.

## Rider Instructions

### Installation

Install the app on your phone. You can find the app on both the
[Apple Store](https://www.apple.com/app-store/) and the 
[Google Play Store](https://play.google.com). Search for "eBrevet" by "CTNadovich".  *Make sure you
have the latest version of the app installed in your phone before you
start riding an event.  If your app version is too old, you may not be able to start
an event or there may be trouble checking into controls.*

### Rider Name and Number

When you first open the app, you *must* enter your Name and RUSA
ID number. Please make sure you you enter your Rider ID correctly. If
you enter the wrong Rider ID, you wll not be able to use the app
till this is corrected. In the USA, your Rider ID is your RUSA number. 

<img src="https://parando.org/ebrevet/v26/required_settings.png" width=33%/>

Once you've set your name and rider ID number, press "Continue". This will take
you to the main eBrevet Events screen. 

### Downloading Events

The main eBrevet Events screen will show you future events that you
can ride. The first time you run the app, this page will be blank. You
need to download events before anything will appear on the list. These
events come from your "Event Info Source". The default is to 
download PA Rando events. 

If the main eBrevet Events page is blank, or it's been several days
since the last time you updated the page, hit the "Refresh Events
from Server" button. If you have Internet service, in a few seconds
the available events from your chosen Club/Region will appear. 

**IMPORTANT:** *If your Club/Region changes the cues for an event
(control location, start time, route, etc...), you will need to press
"Refresh Events" again when you have Internet access. If you don't do
this, the event data on your phone may be invalid and you won't be
able to ride.*

![eBrevet Screen Shots](https://parando.org/ebrevet/v19/ScreenShots/updating_events_process.png)

Once the latest future events are downloaded to your phone, you should
see cards describing each upcoming event. If the event may be
pre-ridden, a "PRERIDE" button will appear on the lower right of the
event card. On the scheduled day of the event a "RIDE" button will
appear. Press this button to RIDE or PRERIDE the event. 

### Start Code

The first time you choose RIDE/PRERIDE, you will need to enter your
Start Code to start the event. The start code is a four character code
printed on your brevet card, or available from the event
organizer. Every rider has a different start code.  If your Start Code
isn't working, make sure you have the latest version of the events
refreshed from the Server, and that you have the latest version of the
eBrevet app. 

### Control Check In

Once you have started the event you need to check in to every control,
including (in some cases) the start control.  

To be able to check in to a control, you
need to be physically near the control and the time of day must be
within the open/close interval of that control. When you are eligible
to check in, a "Check In" button will appear. Click this and the Check
In dialog will open. To actually check in, press the "CHECK IN NOW"
button. You can enter an optional check-in comment that will be posted
to the event chat channel. 

![eBrevet Screen Shots](https://parando.org/ebrevet/v19/ScreenShots/check_in_sequence.png)

When you press the "CHECK IN NOW" button, your check-in is recorded on
your phone and the app will attempt to report the check-in to your
Club/Region's server. After you dismiss the check-in dialogs and
return to the ride page, you will see either a orange three-dots icon,
or a green check next to the control. The green check means you've
checked in and your check-in time has been uploaded to the Club/Region
server. Ride on with confidence that your proof of passage by that
control is solid.

On the other hand, if you see an orange three-dots icon, that means
the app itself has recorded your check-in, but your check-in has not
yet been uploaded to the Club/Region. This will occur if your phone is
in Airplane Mode or if there is no data service on your phone. At some
point in the future when your phone has internet service again, press
the "Upload Results" button and you should see all your orange marks
turn into green checks. 

**IMPORTANT:** *Be sure all your controls show green checks at the end
of the event. When all your controls are green you have officially
completed the event and your results have been recorded at the
Club/Region. If you still have some orange three-dot marks next to
controls, you need to find working Internet service and upload your
results ASAP.*

<div style="text-align: center;">
<img src="https://parando.org/ebrevet/v19/ScreenShots/no_yes_upload.png" width=67%/>
</div>

### Abandoning a Ride

While you are riding an event, you can hit the exit arrow on the upper
left, returning to the main eBrevet Events page. To go back to riding
and checking into controls, hit the CONTINUE RIDE button on the event
card. *Should you want to abandon an event*, click the black X button
next to the Riding Now indicator. 

Yes, it's possible to "Un-abandon" (at least in the app -- not sure
about your legs). Just hit "RIDE" again and the app will resume your
ride. 

### Check-In and Finish Codes

A check-in confirmation dialog appers with an official check in
"signature" code. It's wise to write this code and the check-in time
on your paper brevet card as proof of passage, particularly if you see
orange dots indicating that your proof of passage hasn't been uploaded
and backed up at the Club/Region. Should something happen to your
phone, writing down the check in signature code is
proof you were at the control at the required time. 

<img src="https://parando.org/ebrevet/v19/ScreenShots/check_in_code.png" width=33%/>

If for some reason uploads fail and you don't have green checks on all
your controls when you've finished an event, now it's *really* a good
idea to write those check-in codes onto your paper brevet card. There
will also be an event Finish Code that certifies you checked into all
the controls at the proper times and in the right order! 

### Auto Check-In for Mass Start

With organized mass-start brevets, the app will automatically check
you into the first control and give you a start time of the "official"
brevet start time, independent of when you actually start. This
"auto-start-checkin" is a convenience 
for events where everyone starts together. 

For such events, you can enter your start code into eBrevet any time
within a grace period before the actual start. Then you wait till the organizer
says "GO!", and you start riding. You don't have to worry about
opening eBrevet after the "GO!" to check into the start for these mass
start events. It's already done. Of course, for all subsequent
controls you will need to check in using eBrevet in the usual way.

### Auto Check-In for Perms, Pre-Rides, and Free Starts

With non-mass-start events, after you enter the start code and are near the 
start control at the correct time, 
the app will ask if you optionally want to check into the start control. If you
say YES, it will check you in immediately. 

On the other hand, if you say NO to the auto check-in prompt (or maybe you
are too far away from the start, or at the wrong time), then you have not checked into the 
start control; you have not really started the event. You still need 
to go near to the start control at the correct time 
hit the check-in button when you actually want to start. 


### Event Info Source

If you
want to ride non-PA events, you will need to select the "Event Info Source", which is
where the app goes to fetch information about the events you can ride. 

The info source selection can be
changed in the Settings menu reached through the "hamburger" icon on
the upper left, or by clicking the search-settings icon to the right
of the "Update event data" button. You will want to set your Event
Info Source to be the RUSA Club/Region or ACP Club for the events you
want to ride. You will only see events from the Club/Region you
select. 

<img src="https://parando.org/ebrevet/v26/no_events_yet.png" width=50%/>


The app presents a list of regions in the US. The default is PA:
Eastern, but any US region can be selected. Please only select regions
that support eBrevet.  If a region does not support eBrevet, you will
not be able to use eBrevet for those events. Talk to your RBA and RUSA
about supporting eBrevet EPP for the events you want to ride. More
supported regions are being added all the time.  

There is also an option for selecting a Custom Event Data URL. This
allows you to enter a special URL given to you by your RBA or event
organizer, allowing you to use eBrevet even if your region is not on
the Brevet Region list built into eBrevet. 


### Side Drawer Menu

On the main eBrevet page you will see three horizontal lines in the
upper left corner (the so called hamburger icon). Clicking this will
open the side drawer menu. This menu allows you to access app settings
(eg Rider Name, Rider ID, Event Info Source), as well as Past Events, 
a log of app activity, 
and the About eBrevet dialog. 

<img src="https://parando.org/ebrevet/v26/main_menu.png" width=33%/>


### Past Events

After your complete an event, the results will be visible on the "Past
Events" page accessible from the drawer menu. Past events are stored
on your phone. Should the app be uninstalled, Past Events will be
erased.

![eBrevet Screen Shots](https://parando.org/ebrevet/v19/ScreenShots/finish_sequence.png)

### Sharable Finish Certificate

A good way to finalize your proof of passage for a past event and make
sure your results are also stored in Le Grand Livre for posterity is
to share your certificate of completion. Each event you've finished
will show a CERTIFICATE button. If you press this button, a
certificate of completion will appear. On the lower right of the
certificate there is a "share" icon. Press this and your phone's
share media page will open. You can use this to save the certificate
to photos, google or dropbox, or to attach it to an email or social
media post. 

### Activity Log

The side drawer menu provides access to the Activity Log. 
The app compiles a text log of its recent activity that is 
displayed through this menu entry. Normally riders will have
no need to look at the app activity log, but in case there are problems with the app, 
the log might show error messages and other information that could 
help them debug problems. 


## Club/Region Webserver Support

In order to support the eBrevet app for your Club/Region/Organization,
you will need to configure a webserver to provide event details in
JSON format on a public URL, and to accept JSON formatted check-in
results on another URL. This can be as simple as a static JSON file,
or a dynamic database. The randonneuring.org webserver can provide
proxy eBrevet web support for any club, or it can forward to the club
webserver.

### Future Events JSON

By default, eBrevet will attempt to download future event JSON data from the URL

&nbsp;&nbsp;&nbsp;  `https://randonneuring.org/ebrevet/future_events/XXXXXX`

Where XXXXXX represents the ACP club code of the region's controlling
club. The randonneuring.org server can either handle that request
(assuming it has info on the club's events), or redirect that request
to the desired club webserver. Alternatively, clubs can have their
server URL compiled into eBrevet to avoid the redirect.

The future_events details provided in JSON format by the server must
contain several required fields. At the top level of the JSON map, three fields are required

- `minimum_app_version` The minimum version of the app that is required to be able to download this event data

- `event_list` JSON list containing data for each event.

- `event_errors` List of errors that occured when generating the event_list. Normally empty. 

For each event in the event list, there is a map describing the event with fields as follows

- `event_id` Globally unique event ID string (eg: ACPClubCode-EventNumber)
- `name` Name of event without distance (eg: 'EndlessMountains')
- `distance` Official distance in integer KM (eg: 200)
- `sanction` Sanctioning body (eg: RUSA, ACP, RM, ...)
- `start_city` City name (eg: Easton)
- `start_state` State code (eg: PA)
- `cue_version` Integer version number for cues (eg: 3). Used in generating start codes. 
- `club_acp_code` Numeric club code (eg: 938017)
- `checkin_post_url` The URL where checkins should be directed (eg: https://myclub.org/ebrevet/check-in/999997-403)
- `event_info_url` The URL where riders can get event information (eg: https://myclub.org/info/event/999997-403)
- `organizer_name` Name of the RBA or Event Organizer (eg: John Smith) 
- `organizer_phone` Emergency phone for RBA or Event organizer (eg: +1.8005551212)
- `start_time_window` JSON map of start time information (see below)
- `controls` List of controls (see below)
                
To see a live example future_events JSON object, visit the PA Rando (ACP
club 938017) implementation

&nbsp;&nbsp;&nbsp;  https://randonneuring.org/ebrevet/future_events/938017

The future_events JSON record can be produced in a variety of ways,
including manually, cutting and pasting it from the RWGPS route and
other data. Alternatively, the required information can be extracted
automatically from the RWGPS data by means of a computer program. If
your club uses RWGPS cue markup as described in the 
[Cue Wizard](https://parando.org/cue_wizard.html) system, or similar,
automatic control info extraction is facilitated. See the Cue Wizard
documentation source code for example methods that are free to copy
and use. 

### Start Time Window

eBrevet supports a variety of event start 'styles'.  

- MassStart: Everyone gets the same start time. Automatic check in
at the start control within the time window that begins 
with the grace period before the start, and ends to the close time
of the start control. Distance
to control doesn't matter (it is assumed that the organizer, not
the eBrevet app, polices
location/time of the mass start).

- FreeStart: Start time is individually determined by actual manual check-in at
the start control, which must be within a specified time window
and distance to control must be within proximity limit.

- PreRide: Start time is individually determined by actual manual check-in at
the start control, which must be within the 15 day pre-ride window
and before any MassStart/FreeStart window begins. The distance to the start control must
be within the proximity limit.

- Permanent: Start time is individually determined by actual manual check-in at
the start control, which can be any time. The distance to the start control must
be within the proximity limit.

The start format of a particular event is specified by the `start_time_window` tag. 
This value for this tag is a map with the following tags

- `on_time` The advertised start time for a mass start, or the 'nominal' start time
for a free start. Time zone is UTC and the format is ISO 8601. 
For permanents or pre-rides, this is ignored. 

- `early` Specifies the begining of the time window for a free start. 
Positive integer number of minutes before `on_time` when it is allowed to start the event. 

- `late` Specifies the end of the time window for a free start. 
Positive integer number of minutes after `on_time` when it is allowed to start the event. 

- `start_style` One of the following: `massStart`, `freeStart`, `permanent`, or `preRide`.

As an example, for an ordinary mass start event on July 8th 2023 at 6AM EDT, the start_time_window map would be 

```
{"on_time":"2023-07-08T10:00:00+00:00","start_style":"massStart"}
```

### Controls

The controls are specified under the `controls` tag as a JSON list. Each entry in the list describes
a control with a JSON map. The controls must be in consecutive order in the list, starting with the start control and 
ending with the finish control.  The map entry for each control contains the following required fields

- `dist_mi` Exact distance in miles from the start to this control. The value of `dist_mi` for the start control is assumed to be 0.0 miles. 
- `long` East longitude of the control in decimal degrees. Values for this in the USA will be negative. 
- `lat` North lattitude of the control in decimal degrees. Values for this in the USA will be positive. 
- `name` Descriptive text name of the control (eg "Turkey Hill Minit Mart")
- `open` Open time of control in time zone UTC in ISO 8661 format (eg: 2023-07-08T10:46:00+00:00)
- `close` Open time of control in time zone UTC in ISO 8661 format (eg: 2023-07-08T10:46:00+00:00)

The open/close time of the start control in the control list is arbitrary and does not have to bear any relationship to the 
start time of the event given in the `start_time_window` map.  The open/close time of the start given in 
the control list is subtracted from 
the open/close times of each subsequent control in the list to determine the relative open/close time difference between the controls. This 
difference is then added to the actual start time based on the start style, to yield the actual open/close time 
of each control. For example, if the open time of the start control is 6AM, and the open time of the next control is 7:30AM, 
this is a one and a half hour difference. If a rider actually starts at 5AM with a freeStart style event, then their first control will open at 6:30 AM. 

Two optional fields are supported in this data structure, and if available will be displayed as 
part of the detailed control description, but are otherwise not used. 

- `style` Style of control for traditional brevet purposes (eg: staffed, merchant, photo, etc... )
- `address` Street address of control (eg: 123 Main St, Anytown, NJ)





### App Version

A top level key in the future_events JSON record is 'minimum_app_version'. 
It's important that the record include this key with value set to the 
minimum version of the eBrevet app that can successfully parse all 
the fields in the record. Should the record be enhanced with fields
that are unsupported by older versions of the app, this 'minimum_app_version'
key allows the app to recognize the  incompatibility and refuse to download
events till it's updated. 

Similarly, the check_in record will have an 'app_version' key. The webserver
should use the value of this key to determine its 
compatibility with the app checking in. 

### Control Check In JSON

When riders check into a control, if internet is available the eBrevet
app will attempt to POST a JSON checkin record to a URL specified by
the `checkin_post_url` field in the future_events JSON data. The
checkin record will include all control checkins that have occured up
to the current time, every time. The server should record the first
checkin for each control and is free to ignore the rest. 

The checkin will also include an overall outcome determination that
will say "finish" when all the controls have been checked, otherwise
it will say "active" if the rider is still riding, or "dnf" or "dnq"
if the rider has failed to complete the brevet. 

An example of the checkin record is the following

```
{"event_id":"938017-405","rider_id":"987654","control_index":"0","comment":"Volunteer pre-ride. Automatic Check In","outcome":{"overall_outcome":"active","last_upload":null,"check_in_times":{"0":"2023-07-06T10:21:08.411891Z"}},"app_version":"1.2.2","proximity_radius":"500.0","proximity_override":"true","open_override":"NO","start_style":"preRide","rider_location":"39.9469517N, -75.1870467E","last_loc_update":"2023-07-06T10:20:56.454889Z","timestamp":"2023-07-06T10:21:08.413137Z","signature":"23B0B361"}
```

If the received checkin record is decoded successfully by the
Club/Region server, it can internally record and display checkin information as desired on 
the Club/Region website.

On a successful decode of the checkin record, the sever should reply
with a JSON acknowledgement that includes `"status";"OK"` and
minimally looks like this 

```
{"status":"OK","event_id":"938017-382","rider_id":"5456"}
```

An additional "notes" fields can be added to the acknowledgement that aid in debugging. These 'notes'
are not used by the app, but will appear in the app activity log. For example.

```
{"status":"OK","event_id":"938017-382","rider_id":"5456","notes":["Check In at control 0","PRERIDE MODE SET","Comment: Volunteer pre-ride. Automatic Check In","Outcome: active","Check Ins: 1"]}
```

he Club/Region server can internally record and display checkin information as desired on their website.

Explanations of the checkin fields are as follows:

- `event_id` A unique string that identifies the event. It must be unique worldwide making it impossible for there to ever be two events with the same ID. This must consist of the ACP club code and the club-specific unique event ID separated by
a dash. 

- `rider_id` The rider's RUSA ID number

- `control_index` If the rider is currently checking in to a control, this field will appear giving the control number corresponding to the numbering used in the future_events control list for this control. If a rider is not at a control, this field will be absent. The index numbering system corresponds to however the controls were numbered in the future_events object. Typically the start control index is zero. 

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

- `notes` An undefined string=value map that contains debugging information. Displayed in app log.

### Secrets

Club/region secrets are compiled into eBrevet. There is a general secret that will be used
in case a club hasn't selected their own unique secret. Refer to the file [region.dart](lib/region.dart) for details of how the secret is set for a region.

## Privacy Policy

See the [Privacy Policy document](PRIVACY)

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

