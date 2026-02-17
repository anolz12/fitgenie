import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBwEK_rUVj38ffc2ZeN0p16yGKG9OQPnt0',
    appId: '1:793336851674:android:8e01fcd77bcfd6d164c9e3',
    messagingSenderId: '793336851674',
    projectId: 'fitgenie-anolal-51d45',
    storageBucket: 'fitgenie-anolal-51d45.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
    iosBundleId: 'com.example.fitgenie',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
    iosBundleId: 'com.example.fitgenie',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCxKjbRIEqOQc85OH3dnXPCotuXrV_nilc',
    appId: '1:793336851674:web:ae8ccbe9edcc631d64c9e3',
    messagingSenderId: '793336851674',
    projectId: 'fitgenie-anolal-51d45',
    storageBucket: 'fitgenie-anolal-51d45.firebasestorage.app',
    authDomain: 'fitgenie-anolal-51d45.firebaseapp.com',
    measurementId: 'G-XKXF6K40FQ',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCxKjbRIEqOQc85OH3dnXPCotuXrV_nilc',
    appId: '1:793336851674:web:0c1fe4038da3be4664c9e3',
    messagingSenderId: '793336851674',
    projectId: 'fitgenie-anolal-51d45',
    authDomain: 'fitgenie-anolal-51d45.firebaseapp.com',
    storageBucket: 'fitgenie-anolal-51d45.firebasestorage.app',
    measurementId: 'G-ETWV6FR4KN',
  );

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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return windows;
      case TargetPlatform.fuchsia:
        return android;
    }
  }
}
