import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_review/in_app_review.dart';
import 'package:location/location.dart';
import 'package:taxipassau_driver/constant/constant.dart';
import 'package:taxipassau_driver/constant/logdata.dart';
import 'package:taxipassau_driver/constant/show_toast_dialog.dart';
import 'package:taxipassau_driver/controller/subscription_controller.dart';
import 'package:taxipassau_driver/model/driver_location_update.dart';
import 'package:taxipassau_driver/model/user_model.dart';
import 'package:taxipassau_driver/page/add_bank_details/show_bank_details.dart';
import 'package:taxipassau_driver/page/auth_screens/login_screen.dart';
import 'package:taxipassau_driver/page/auth_screens/vehicle_info_screen.dart';
import 'package:taxipassau_driver/page/car_service_history/car_service_history_screen.dart';
import 'package:taxipassau_driver/page/dash_board.dart';
import 'package:taxipassau_driver/page/document_status/document_status_screen.dart';
import 'package:taxipassau_driver/page/localization_screens/localization_screen.dart';
import 'package:taxipassau_driver/page/my_profile/my_profile_screen.dart';
import 'package:taxipassau_driver/page/parcel_service/all_parcel_screen.dart';
import 'package:taxipassau_driver/page/parcel_service/search_parcel_screen.dart';
import 'package:taxipassau_driver/page/privacy_policy/privacy_policy_screen.dart';
import 'package:taxipassau_driver/page/subscription_plan_screen/subscription_history_screen.dart';
import 'package:taxipassau_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:taxipassau_driver/page/terms_of_service/terms_of_service_screen.dart';
import 'package:taxipassau_driver/page/wallet/wallet_screen.dart';
import 'package:taxipassau_driver/service/api.dart';
import 'package:taxipassau_driver/utils/Preferences.dart';

class DashBoardController extends GetxController {
  Location location = Location();
  late StreamSubscription<LocationData> locationSubscription;
  Timer? locationUpdateTimer;

  @override
  void onInit() {
    getUsrData();
    locationSubscription = location.onLocationChanged.listen((event) {});
    getCurrentLocation();
    updateToken();
    updateCurrentLocation();
    getPaymentSettingData();
    // startDriverLocationAutoUpdate();
    super.onInit();
  }

  @override
  void onClose() {
    locationUpdateTimer?.cancel();
    locationSubscription.cancel();
    super.onClose();
  }

  updateToken() async {
    // use the returned token to send messages to users from your custom server
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      updateFCMToken(token);
    }
  }

  getCurrentLocation() async {
    LocationData location = await Location().getLocation();
    List<geocoding.Placemark> placeMarks =
        await geocoding.placemarkFromCoordinates(
            location.latitude ?? 0.0, location.longitude ?? 0.0);
    geocoding.Placemark place = placeMarks.first;

    String address =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
    for (var i = 0; i < Constant.allTaxList.length; i++) {
      if (placeMarks.first.country.toString().toUpperCase() ==
          Constant.allTaxList[i].country!.toUpperCase()) {
        Constant.taxList.add(Constant.allTaxList[i]);
      }
    }
    print(Constant.taxList.length);

    // driverLocationUpdateAddress(location.latitude.toString(), location.longitude.toString(), address);
    setCurrentLocation(
        location.latitude.toString(), location.longitude.toString());
  }

  getDrawerItem() {
    drawerItems = [
      DrawerItem('All Rides'.tr, 'assets/icons/ic_car.svg',
          section:
              "${"Rides".tr}${(Constant.parcelActive.toString() == "yes" && userModel.value.userData?.parcelDelivery.toString() == "yes") ? " & Parcels:".tr : ":"}",
          navigate: () {
        Get.back();
      }),
      if (Constant.parcelActive.toString() == "yes" &&
          userModel.value.userData?.parcelDelivery.toString() == "yes")
        DrawerItem('Parcel Service'.tr, 'assets/icons/ic_parcel_vehicle.svg',
            navigate: () {
          Get.back();
          Get.to(SearchParcelScreen());
        }),
      if (Constant.parcelActive.toString() == "yes" &&
          userModel.value.userData?.parcelDelivery.toString() == "yes")
        DrawerItem('All Parcel'.tr, 'assets/icons/ic_all_car.svg',
            navigate: () {
          Get.back();
          Get.to(const AllParcelScreen());
        }),
      DrawerItem('Documents'.tr, 'assets/icons/ic_car.svg',
          section: 'Vehicle & Service Management:'.tr, navigate: () {
        Get.back();
        Get.to(DocumentStatusScreen());
      }),
      DrawerItem('Vehicle information'.tr, 'assets/icons/ic_parcel_vehicle.svg',
          navigate: () {
        Get.back();
        Get.to(const VehicleInfoScreen());
      }),
      DrawerItem('Car Service History'.tr, 'assets/icons/ic_all_car.svg',
          navigate: () {
        Get.back();
        Get.to(const CarServiceBookHistory());
      }),
      DrawerItem('My Profile'.tr, 'assets/icons/ic_profile.svg',
          section: 'Account & Financials:'.tr, navigate: () {
        Get.back();
        Get.to(MyProfileScreen());
      }),
      DrawerItem('My Earnings'.tr, 'assets/icons/ic_wallet.svg', navigate: () {
        Get.back();
        Get.to(WalletScreen());
      }),
      DrawerItem('Add Bank'.tr, 'assets/icons/ic_bank.svg', navigate: () {
        Get.back();
        Get.to(const ShowBankDetails());
      }),
      if (Constant.subscriptionModel == true ||
          Constant.adminCommission?.statut == 'yes')
        DrawerItem('Subscription'.tr, 'assets/icons/ic_subscription.svg',
            section: "Subscription", navigate: () {
          Get.back();
          Get.delete<SubscriptionController>();
          Get.to(SubscriptionPlanScreen(
            isbackButton: true,
          ))?.then((value) {
            if (value == true) {
              getUsrData();
            }
          });
        }),
      DrawerItem('Subscription History'.tr, 'assets/icons/ic_history.svg',
          navigate: () {
        Get.back();
        Get.to(SubscriptionHistoryScreen());
      }),
      DrawerItem('Change Language'.tr, 'assets/icons/ic_lang.svg',
          section: 'Settings & Support:'.tr, navigate: () {
        Get.back();
        Get.to(const LocalizationScreens(intentType: "dashBoard"));
      }),
      DrawerItem('Terms of Service'.tr, 'assets/icons/ic_terms.svg',
          navigate: () {
        Get.back();
        Get.to(const TermsOfServiceScreen());
      }),
      DrawerItem('Privacy Policy'.tr, 'assets/icons/ic_privacy.svg',
          navigate: () {
        Get.back();
        Get.to(const PrivacyPolicyScreen());
      }),
      DrawerItem('Dark Mode'.tr, 'assets/icons/ic_dark.svg', isSwitch: true,
          navigate: () {
        Get.back();
      }),
      DrawerItem('Rate the App'.tr, 'assets/icons/ic_star_line.svg',
          section: 'Feedback & Support'.tr, navigate: () async {
        try {
          if (await inAppReview.isAvailable()) {
            inAppReview.requestReview();
          } else {
            inAppReview.openStoreListing();
          }
        } catch (e) {
          log("Error triggering in-app review: $e");
        }
      }),
      DrawerItem('Log Out'.tr, 'assets/icons/ic_logout.svg', navigate: () {
        Preferences.clearKeyData(Preferences.isLogin);
        Preferences.clearKeyData(Preferences.user);
        Preferences.clearKeyData(Preferences.userId);
        Get.offAll(const LoginScreen());
      }),
    ];
  }

  Rx<UserModel> userModel = UserModel().obs;

  getUsrData() async {
    userModel.value = Constant.getUserData();
    try {
      Map<String, String> bodyParams = {
        'phone': userModel.value.userData!.phone.toString(),
        'user_cat': "driver",
        'email': userModel.value.userData!.email.toString(),
        'login_type': userModel.value.userData!.loginType.toString(),
      };
      final response = await http.post(Uri.parse(API.getProfileByPhone),
          headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.getProfileByPhone} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBodyPhone = json.decode(response.body);
      if (response.statusCode == 200 &&
          responseBodyPhone['success'] == "success") {
        log("userModel.value.userData!.online :: ${response.body.toString()}");
        ShowToastDialog.closeLoader();
        UserModel? value = UserModel.fromJson(responseBodyPhone);
        await Preferences.setString(Preferences.user, jsonEncode(value));
        userModel.value = value;
        isActive.value =
            userModel.value.userData!.online == "yes" ? true : false;
      } else if (response.statusCode == 200 &&
          responseBodyPhone['success'] != "success") {
        if (responseBodyPhone['error'] == 'Driver Not Found') {
          Preferences.clearKeyData(Preferences.isLogin);
          Preferences.clearKeyData(Preferences.user);
          Preferences.clearKeyData(Preferences.userId);
          ShowToastDialog.showToast(
              'An admin has deleted your account. You no longer have access.'
                  .tr);
          Get.offAll(const LoginScreen());
        }
      }
    } catch (e) {
      rethrow;
    }
    log("Constant.parcelActive :: ${Constant.parcelActive.toString() == "yes"}  || ${userModel.value.userData?.parcelDelivery.toString() == "yes"}");
    getDrawerItem();
  }

  RxBool isActive = true.obs;
  RxInt selectedDrawerIndex = 0.obs;
  var drawerItems = [];
  final InAppReview inAppReview = InAppReview.instance;

  updateCurrentLocation() async {
    if (isActive.value) {
      PermissionStatus permissionStatus = await location.hasPermission();
      if (permissionStatus == PermissionStatus.granted) {
        location.enableBackgroundMode(enable: true);
        location.changeSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter:
                double.parse(Constant.driverLocationUpdateUnit.toString()));
        locationSubscription =
            location.onLocationChanged.listen((locationData) async {
          LocationData currentLocation = locationData;
          Constant.currentLocation = locationData;
          List<geocoding.Placemark> placeMarks =
              await geocoding.placemarkFromCoordinates(
            currentLocation.latitude ?? 0.0,
            currentLocation.longitude ?? 0.0,
          );
          geocoding.Placemark place = placeMarks.first;
          String address =
              "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

          DriverLocationUpdate driverLocationUpdate = DriverLocationUpdate(
              rotation: currentLocation.heading.toString(),
              active: isActive.value,
              driverId: Preferences.getInt(Preferences.userId).toString(),
              driverLatitude: currentLocation.latitude.toString(),
              driverLongitude: currentLocation.longitude.toString());
          Constant.driverLocationUpdate
              .doc(Preferences.getInt(Preferences.userId).toString())
              .set(driverLocationUpdate.toJson());
          driverLocationUpdateAddress(currentLocation.latitude.toString(), currentLocation.longitude.toString(), address);
          setCurrentLocation(currentLocation.latitude.toString(),
              currentLocation.longitude.toString());
        });
      } else {
        location.requestPermission().then((permissionStatus) {
          if (permissionStatus == PermissionStatus.granted) {
            location.enableBackgroundMode(enable: true);
            location.changeSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter:
                    double.parse(Constant.driverLocationUpdateUnit.toString()));
            locationSubscription =
                location.onLocationChanged.listen((locationData) async {
              LocationData currentLocation = locationData;
              Constant.currentLocation = locationData;
              List<geocoding.Placemark> placeMarks =
                  await geocoding.placemarkFromCoordinates(
                currentLocation.latitude ?? 0.0,
                currentLocation.longitude ?? 0.0,
              );

              geocoding.Placemark place = placeMarks.first;
              String address =
                  "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

              DriverLocationUpdate driverLocationUpdate = DriverLocationUpdate(
                  rotation: currentLocation.heading.toString(),
                  active: isActive.value,
                  driverId: Preferences.getInt(Preferences.userId).toString(),
                  driverLatitude: currentLocation.latitude.toString(),
                  driverLongitude: currentLocation.longitude.toString());
              Constant.driverLocationUpdate
                  .doc(Preferences.getInt(Preferences.userId).toString())
                  .set(driverLocationUpdate.toJson());
              driverLocationUpdateAddress(currentLocation.latitude.toString(), currentLocation.longitude.toString(), address);
              setCurrentLocation(currentLocation.latitude.toString(),
                  currentLocation.longitude.toString());
            });
          }
        });
      }
    } else {
      DriverLocationUpdate driverLocationUpdate = DriverLocationUpdate(
          rotation: "0",
          active: false,
          driverId: Preferences.getInt(Preferences.userId).toString(),
          driverLatitude: "0",
          driverLongitude: "0");
      Constant.driverLocationUpdate
          .doc(Preferences.getInt(Preferences.userId).toString())
          .set(driverLocationUpdate.toJson());
    }
  }

  // deleteCurrentOrderLocation() {
//   RideData? rideData = Constant.getCurrentRideData();
//   if (rideData != null) {
//     String orderId = "";
//     if (rideData.rideType! == 'driver') {
//       orderId = '${rideData.idUserApp}-${rideData.id}-${rideData.idConducteur}';
//     } else {
//       orderId = (double.parse(rideData.idUserApp.toString()) < double.parse(rideData.idConducteur!))
//           ? '${rideData.idUserApp}-${rideData.id}-${rideData.idConducteur}'
//           : '${rideData.idConducteur}-${rideData.id}-${rideData.idUserApp}';
//     }
//     Location location = Location();
//     location.enableBackgroundMode(enable: false);
//     Constant.locationUpdate.doc(orderId).delete().then((value) async {
//       await updateCurrentLocation(data: rideData);
//       Preferences.clearKeyData(Preferences.currentRideData);
//       locationSubscription.cancel();
//     });
//   }
// }

  // Future<void> startDriverLocationAutoUpdate() async {
  //   driverLocationUpdateNow();
  //   await location.enableBackgroundMode(enable: true);
  //   locationUpdateTimer?.cancel();
  //   locationUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
  //     print("Timer fired at ${DateTime.now()}");
  //     print("📡 Checking background location...");
  //     LocationData? locationData;
  //     try {
  //       locationData = await location.getLocation();
  //       print("📍 LocationData: lat=${locationData.latitude}, long=${locationData.longitude}");
  //     } catch (e) {
  //       print("❌ Failed to get location: $e");
  //     }
  //     await driverLocationUpdateNow();
  //   });
  //   print("Timer fired at1 ${DateTime.now()}");
  // }

  // void startDriverLocationAutoUpdate() async {
  //   await location.enableBackgroundMode(enable: true);
  //   locationUpdateTimer?.cancel();
  //
  //   // Run immediately once
  //   driverLocationUpdateNow();
  //
  //   // Run every 1 minute
  //   locationUpdateTimer =
  //       Timer.periodic(const Duration(minutes: 1), (timer) async {
  //     print("⏰ Auto-update triggered at ${DateTime.now()}");
  //     await driverLocationUpdateNow();
  //   });
  // }
  //
  // Future<void> driverLocationUpdateNow() async {
  //   print("🚗 driverLocationUpdateNow() fired at ${DateTime.now()}");
  //   try {
  //     // // LocationData locationData = await location.getLocation();
  //     // print("📍 LocationData: lat=${locationData.latitude}, long=${locationData.longitude}");
  //     //
  //     // if (locationData.latitude == null || locationData.longitude == null) {
  //     //   print("⚠️ LocationData is null, skipping API call");
  //     //   return;
  //     // }
  //
  //     List<geocoding.Placemark> placeMarks =
  //         await geocoding.placemarkFromCoordinates(
  //       Constant.currentLocation!.latitude!,
  //       Constant.currentLocation!.longitude!,
  //     );
  //
  //     print("📍 Got ${placeMarks.length} placemarks");
  //     if (placeMarks.isEmpty) {
  //       print("⚠️ No placemarks found, skipping");
  //       return;
  //     }
  //
  //     geocoding.Placemark place = placeMarks.first;
  //     String address =
  //         "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
  //
  //     print("🏠 Address resolved: $address");
  //     print("🌐 Calling driverLocationUpdateAddress...");
  //
  //     var res = await driverLocationUpdateAddress(
  //       Constant.currentLocation!.latitude!.toString(),
  //       Constant.currentLocation!.longitude!.toString(),
  //       address,
  //     );
  //
  //     print("✅ driverLocationUpdateAddress response: $res");
  //   } catch (e, s) {
  //     print("❌ Exception in driverLocationUpdateNow: $e");
  //     print(s);
  //   }
  // }

  Future<dynamic> driverLocationUpdateAddress(
      String latitude, String longitude, String address) async {
    try {
      Map<String, dynamic> bodyParams = {
        'driver_id': Preferences.getInt(Preferences.userId),
        'latitude': latitude,
        'longitude': longitude,
        'address': address
      };
      final response = await http.post(Uri.parse(API.driverLocationUpdate),
          headers: API.header, body: jsonEncode(bodyParams));
      showLog("API1 :: URL :: ${API.driverLocationUpdate} ");
      showLog("API1 :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API1 :: Request Header :: ${API.header.toString()} ");
      showLog("API1 :: responseStatus :: ${response.statusCode} ");
      showLog("API1 :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        Preferences.clearKeyData(Preferences.isLogin);
        Preferences.clearKeyData(Preferences.user);
        Preferences.clearKeyData(Preferences.userId);
        ShowToastDialog.showToast(
            'An admin has deleted your account. You no longer have access.'.tr);
        Get.offAll(const LoginScreen());
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> setCurrentLocation(String latitude, String longitude) async {
    try {
      Map<String, dynamic> bodyParams = {
        'id_user': Preferences.getInt(Preferences.userId),
        'user_cat': userModel.value.userData!.userCat,
        'latitude': latitude,
        'longitude': longitude
      };
      final response = await http.post(Uri.parse(API.updateLocation),
          headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.updateLocation} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        Preferences.clearKeyData(Preferences.isLogin);
        Preferences.clearKeyData(Preferences.user);
        Preferences.clearKeyData(Preferences.userId);
        ShowToastDialog.showToast(
            'An admin has deleted your account. You no longer have access.'.tr);
        Get.offAll(const LoginScreen());
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> updateFCMToken(String token) async {
    try {
      Map<String, dynamic> bodyParams = {
        'user_id': Preferences.getInt(Preferences.userId),
        'fcm_id': token,
        'device_id': "",
        'user_cat': userModel.value.userData!.userCat
      };
      final response = await http.post(Uri.parse(API.updateToken),
          headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.updateToken} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseBody;
      } else {}
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> changeOnlineStatus(bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.changeStatus),
          headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.changeStatus} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      print("====>");
      print(response.statusCode);
      print(response.body);
      if (response.statusCode == 200) {
        ShowToastDialog.closeLoader();
        updateCurrentLocation();
        return responseBody;
      } else {
        ShowToastDialog.closeLoader();
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> getPaymentSettingData() async {
    try {
      final response =
          await http.get(Uri.parse(API.paymentSetting), headers: API.header);
      showLog("API :: URL :: ${API.paymentSetting} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        Preferences.setString(
            Preferences.paymentSetting, jsonEncode(responseBody));
      } else if (response.statusCode == 200 &&
          responseBody['success'] == "Failed") {
      } else {}
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }
}
