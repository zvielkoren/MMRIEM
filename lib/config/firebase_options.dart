import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCn3WB_e2oOFmJGUDITBfLd-4_Pg9H6eQs',
    appId: '1:544706941106:web:a4481829851371b0f7f9ab',
    messagingSenderId: '544706941106',
    projectId: 'mamrimegolan',
    authDomain: 'mamrimegolan.firebaseapp.com',
    storageBucket: 'mamrimegolan.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCn3WB_e2oOFmJGUDITBfLd-4_Pg9H6eQs',
    appId: '1:544706941106:android:a4481829851371b0f7f9ab',
    messagingSenderId: '544706941106',
    projectId: 'mamrimegolan',
    storageBucket: 'mamrimegolan.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCn3WB_e2oOFmJGUDITBfLd-4_Pg9H6eQs',
    appId: '1:544706941106:ios:a4481829851371b0f7f9ab',
    messagingSenderId: '544706941106',
    projectId: 'mamrimegolan',
    storageBucket: 'mamrimegolan.appspot.com',
    iosClientId: '544706941106-ios.apps.googleusercontent.com',
    iosBundleId: 'com.zvielkoren.mmriem',
  );
}
