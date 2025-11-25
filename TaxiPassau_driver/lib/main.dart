// ignore_for_file: empty_catches, must_be_immutable, unused_local_variable, deprecated_member_use
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxipassau_driver/constant/constant.dart';
import 'package:taxipassau_driver/controller/dash_board_controller.dart';
import 'package:taxipassau_driver/controller/settings_controller.dart';
import 'package:taxipassau_driver/firebase_options.dart';
import 'package:taxipassau_driver/on_boarding_screen.dart';
import 'package:taxipassau_driver/page/auth_screens/login_screen.dart';
import 'package:taxipassau_driver/page/dash_board.dart';
import 'package:taxipassau_driver/service/api.dart';
import 'package:taxipassau_driver/themes/styles.dart';
import 'package:taxipassau_driver/utils/background_task.dart';
import 'package:taxipassau_driver/utils/dark_theme_provider.dart';
import 'package:workmanager/workmanager.dart';

import 'page/chats_screen/conversation_screen.dart';
import 'page/localization_screens/localization_screen.dart';
import 'page/subscription_plan_screen/subscription_plan_screen.dart';
import 'service/localization_service.dart';
import 'utils/Preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Preferences.initPref();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  var request = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (!Platform.isIOS) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt > 28) {
      AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
    }
  }

  HttpOverrides.global = MyHttpOverrides();
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  await Workmanager().registerPeriodicTask(
    "driverLocationTask",
    backgroundTaskName,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(minutes: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    getCurrentAppTheme();
    setupInteractedMessage(context);
    Future.delayed(const Duration(seconds: 3), () {
      if (Preferences.getString(Preferences.languageCodeKey).toString().isNotEmpty) {
        LocalizationService().changeLocale(Preferences.getString(Preferences.languageCodeKey).toString());
      }
      API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);
    });
    super.initState();
  }

  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme = await themeChangeProvider.darkThemePreference.getTheme();
  }

  Future<void> setupInteractedMessage(BuildContext context) async {
    initialize(context);
    await FirebaseMessaging.instance.subscribeToTopic("driver");

    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {}

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        display(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (message.notification != null) {
        if (message.data['status'] == "done") {
          await Get.to(
            ConversationScreen(),
            arguments: {
              'receiverId': int.parse(json.decode(message.data['message'])['senderId'].toString()),
              'orderId': int.parse(json.decode(message.data['message'])['orderId'].toString()),
              'receiverName': json.decode(message.data['message'])['senderName'].toString(),
              'receiverPhoto': json.decode(message.data['message'])['senderPhoto'].toString(),
            },
          );
        } else if (message.data['statut'] == "new" && message.data['statut'] == "rejected") {
          await Get.to(DashBoard());
        } else if (message.data['type'] == "payment received") {
          DashBoardController dashBoardController = Get.put(DashBoardController(), permanent: true);
          dashBoardController.selectedDrawerIndex.value = 4;
          await Get.to(DashBoard());
        }
      }
    });
  }

  Future<void> initialize(BuildContext context) async {
    AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'taxipassaudriver', // id
      'TaxiPassau Notifications', // title
      importance: Importance.high,
    );

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitializationSettings = const DarwinInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: iosInitializationSettings,
    );
    await FlutterLocalNotificationsPlugin().initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) async {},
    );

    await FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  void display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      bool isNew = message.data['statut'] == "new";

      NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          "taxipassaudriver",
          "taxipassaudriver",
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: isNew ? const RawResourceAndroidNotificationSound('notification_sound') : null,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          sound: isNew ? 'notification_sound.aiff' : null,
        ),
      );

      await FlutterLocalNotificationsPlugin().show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      // safely ignore
    }
  }

  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => themeChangeProvider,
      child: Consumer<DarkThemeProvider>(
        builder: (context, value, child) {
          return GetMaterialApp(
            title: 'Taxi Passau Fahrer'.tr,
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(
              themeChangeProvider.darkTheme == 0
                  ? true
                  : themeChangeProvider.darkTheme == 1
                      ? false
                      : themeChangeProvider.getSystemThem(),
              context,
            ),
            locale: LocalizationService.locale,
            fallbackLocale: LocalizationService.locale,
            translations: LocalizationService(),
            builder: EasyLoading.init(),
            home: SafeArea(
              top: false,
              bottom: true,
              child: GetX(
                init: SettingsController(),
                builder: (controller) {
                  final themeChange = Provider.of<DarkThemeProvider>(context);
                  return controller.isLoading.value == true
                      ? Container(
                          child: Constant.loader(context, isDarkMode: themeChange.getThem()),
                        )
                      : Preferences.getString(Preferences.languageCodeKey).toString().isEmpty
                          ? const LocalizationScreens(intentType: "main")
                          : Preferences.getBoolean(Preferences.isFinishOnBoardingKey)
                              ? Preferences.getBoolean(Preferences.isLogin)
                                  ? controller.checkStatus()
                                      ? DashBoard()
                                      : SubscriptionPlanScreen(isbackButton: false, isSplashScreen: true)
                                  : const LoginScreen()
                              : const OnBoardingScreen();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

//
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// }
//
// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
//   }
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Preferences.initPref();
//
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   await FirebaseAppCheck.instance.activate(webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'), androidProvider: AndroidProvider.playIntegrity, appleProvider: AppleProvider.appAttest);
//   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
//
//   var request = await FirebaseMessaging.instance.requestPermission(alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true);
//
//   if (!Platform.isIOS) {
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//     if (androidInfo.version.sdkInt > 28) {
//       AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
//     }
//   }
//   HttpOverrides.global = MyHttpOverrides();
//   runApp(MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
//   @override
//   void initState() {
//     WidgetsBinding.instance.addObserver(this);
//     getCurrentAppTheme();
//     setupInteractedMessage(context);
//     Future.delayed(const Duration(seconds: 3), () {
//       if (Preferences.getString(Preferences.languageCodeKey).toString().isNotEmpty) {
//         LocalizationService().changeLocale(Preferences.getString(Preferences.languageCodeKey).toString());
//       }
//       API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);
//     });
//     super.initState();
//   }
//
//   DarkThemeProvider themeChangeProvider = DarkThemeProvider();
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     getCurrentAppTheme();
//   }
//
//   void getCurrentAppTheme() async {
//     themeChangeProvider.darkTheme = await themeChangeProvider.darkThemePreference.getTheme();
//   }
//
//   Future<void> setupInteractedMessage(BuildContext context) async {
//     initialize(context);
//     await FirebaseMessaging.instance.subscribeToTopic("driver");
//
//     RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
//
//     if (initialMessage != null) {}
//
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       if (message.notification != null) {
//         display(message);
//       }
//     });
//
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
//       if (message.notification != null) {
//         if (message.data['status'] == "done") {
//           await Get.to(
//             ConversationScreen(),
//             arguments: {
//               'receiverId': int.parse(json.decode(message.data['message'])['senderId'].toString()),
//               'orderId': int.parse(json.decode(message.data['message'])['orderId'].toString()),
//               'receiverName': json.decode(message.data['message'])['senderName'].toString(),
//               'receiverPhoto': json.decode(message.data['message'])['senderPhoto'].toString(),
//             },
//           );
//         } else if (message.data['statut'] == "new" && message.data['statut'] == "rejected") {
//           await Get.to(DashBoard());
//         } else if (message.data['type'] == "payment received") {
//           DashBoardController dashBoardController = Get.put(DashBoardController());
//           dashBoardController.selectedDrawerIndex.value = 4;
//           await Get.to(DashBoard());
//         }
//       }
//     });
//   }
//
//   Future<void> initialize(BuildContext context) async {
//     AndroidNotificationChannel channel = const AndroidNotificationChannel(
//       'taxipassaudriver', // id
//       'TaxiPassau Notifications', // title
//       importance: Importance.high,
//     );
//
//     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//     var iosInitializationSettings = const DarwinInitializationSettings();
//     final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: iosInitializationSettings);
//     await FlutterLocalNotificationsPlugin().initialize(initializationSettings, onDidReceiveNotificationResponse: (payload) async {});
//
//     await FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
//   }
//
//   void display(RemoteMessage message) async {
//     try {
//       final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//       const NotificationDetails notificationDetails = NotificationDetails(
//         android: AndroidNotificationDetails("taxipassaudriver", "taxipassaudriver", importance: Importance.max, priority: Priority.high,  sound: RawResourceAndroidNotificationSound('notification_sound'),
//           playSound: true,),
//       );
//
//       await FlutterLocalNotificationsPlugin().show(id, message.notification!.title, message.notification!.body, notificationDetails, payload: jsonEncode(message.data));
//     } on Exception {}
//   }
//
//   GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) {
//         return themeChangeProvider;
//       },
//       child: Consumer<DarkThemeProvider>(
//         builder: (context, value, child) {
//           return GetMaterialApp(
//             title: 'Taxi Passau Fahrer'.tr,
//             debugShowCheckedModeBanner: false,
//             theme: Styles.themeData(
//               themeChangeProvider.darkTheme == 0
//                   ? true
//                   : themeChangeProvider.darkTheme == 1
//                       ? false
//                       : themeChangeProvider.getSystemThem(),
//               context,
//             ),
//             locale: LocalizationService.locale,
//             fallbackLocale: LocalizationService.locale,
//             translations: LocalizationService(),
//             builder: EasyLoading.init(),
//             home: SafeArea(
//               top: false,
//               bottom: true,
//               child: GetX(
//                 init: SettingsController(),
//                 builder: (controller) {
//                   final themeChange = Provider.of<DarkThemeProvider>(context);
//                   return controller.isLoading.value == true
//                       ? Container(child: Constant.loader(context, isDarkMode: themeChange.getThem()))
//                       : Preferences.getString(Preferences.languageCodeKey).toString().isEmpty
//                           ? const LocalizationScreens(intentType: "main")
//                           : Preferences.getBoolean(Preferences.isFinishOnBoardingKey)
//                               ? Preferences.getBoolean(Preferences.isLogin)
//                                   ? controller.checkStatus()
//                                       ? DashBoard()
//                                       : SubscriptionPlanScreen(isbackButton: false, isSplashScreen: true)
//                                   : const LoginScreen()
//                               : const OnBoardingScreen();
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
