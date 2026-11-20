import 'package:flutter/material.dart';

import 'data/database.dart';
import 'data/key_store.dart';
import 'screens/subjects_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = Services(keys: KeyStore(), db: await AppDatabase.open());
  final hasKey = (await services.keys.readKey())?.isNotEmpty ?? false;
  runApp(RepeatXApp(services: services, startWithSubjects: hasKey));
}

/// App-wide services, handed down through [ServicesScope].
class Services {
  Services({required this.keys, required this.db});
  final KeyStore keys;
  final AppDatabase db;
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({super.key, required this.services, required super.child});
  final Services services;

  static Services of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ServicesScope>()!.services;

  @override
  bool updateShouldNotify(ServicesScope oldWidget) => services != oldWidget.services;
}

class RepeatXApp extends StatelessWidget {
  const RepeatXApp({super.key, required this.services, required this.startWithSubjects});
  final Services services;
  final bool startWithSubjects;

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: services,
      child: MaterialApp(
        title: 'RepeatX',
        debugShowCheckedModeBanner: false,
        theme: RX.theme(),
        home: startWithSubjects ? const SubjectsScreen() : const WelcomeScreen(),
      ),
    );
  }
}
