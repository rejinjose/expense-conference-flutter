import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools/riverpod_devtools.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase; 
import 'firebase_options.dart' show DefaultFirebaseOptions; 
import 'app_route_configuration.dart' show routerProvider;

void main() async{

   // 1. Ensure Flutter framework is fully initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase for the current platform (Android, iOS, Web, etc.)
  try{
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully for:${Firebase.app().options.projectId}");
  } catch(e) {
    print("Firebase initialization failed: $e");
  }
  
  await dotenv.load(fileName: ".env");

  runApp(
    ProviderScope(
      observers: [
        RiverpodDevToolsObserver(),
      ],
      child:const MyApp()),
  );
}

class MyApp extends ConsumerWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Personal Diary Flutter',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}