import 'package:ebrevet_card/event_history.dart';
import 'package:ebrevet_card/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'snackbarglobal.dart';
import 'future_events_page.dart';
import 'past_events_page.dart';
import 'future_events.dart';
import 'region.dart';

void main() {
  initSettings().then((_) {
    print("** runApp(MyApp)");
    runApp(MyApp());
  });
}

Future<void> initSettings() async {
  await Settings.init(
    cacheProvider: SharePreferenceCache(),
  );
  FutureEvents.refreshEventsFromDisk(Region.fromSettings())
      .then((_) => EventHistory.load());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: SnackbarGlobal.key,
      title: 'eBrevet Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var style = TextStyle(
      fontSize: 20,
    );

    return Scaffold(
        appBar: AppBar(
          title: Text(
            'eBrevet Card',
            //style: TextStyle(fontSize: 14),
          ),
        ),
        body: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Center(
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(flex: 4),
                  ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                EventsPage(), // will implicitly ride event just activated
                          )),
                      child: Text(
                        'Future Events',
                        style: style,
                      )),
                  Spacer(flex: 1),
                  ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                PastEventsPage(), // will implicitly ride event just activated
                          )),
                      child: Text(
                        'Past Events',
                        style: style,
                      )),
                  Spacer(flex: 1),
                  ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                SettingsPage(), // will implicitly ride event just activated
                          )),
                      child: Text(
                        'Settings',
                        style: style,
                      )),
                  // Spacer(flex: 1),
                  // ElevatedButton(
                  //     onPressed: () =>
                  //         Navigator.of(context).push(MaterialPageRoute(
                  //           builder: (context) =>
                  //               TestPage(), // will implicitly ride event just activated
                  //         )),
                  //     child: Text(
                  //       'Test',
                  //       style: style,
                  //     )),
                  Spacer(flex: 4),
                ],
              ),
            ),
          ),
        ));
  }
}
