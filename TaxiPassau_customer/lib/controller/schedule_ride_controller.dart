import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:taxipassau/constant/logdata.dart';
import 'package:taxipassau/constant/show_toast_dialog.dart';
import 'package:taxipassau/model/ride_model.dart';
import 'package:taxipassau/service/api.dart';
import 'package:taxipassau/utils/Preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ScheduleRideController extends GetxController {
  var isLoading = true.obs;
  var newRideList = <RideData>[].obs;
  var completedRideList = <RideData>[].obs;
  var rejectedRideList = <RideData>[].obs;
  Timer? timer;

  @override
  void onInit() {
    getNewRide(isinit: true);
    timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      getNewRide();
    });
    super.onInit();
  }

  @override
  void onClose() {
    timer?.cancel();
    super.onClose();
  }

  Future<dynamic> getNewRide({bool isinit = false}) async {
    try {
      if (isinit) {
        ShowToastDialog.showLoader("Please wait");
      }
      final response = await http.get(Uri.parse("${API.userAllRides}?id_user_app=${Preferences.getInt(Preferences.userId)}"), headers: API.header);

      showLog("API :: URL :: ${API.userAllRides}?id_user_app=${Preferences.getInt(Preferences.userId)} ");
      showLog("API :: Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        isLoading.value = false;

        RideModel model = RideModel.fromJson(responseBody);

        newRideList.clear();
        completedRideList.clear();
        rejectedRideList.clear();
        log("newRideList :: ${model.data}");
        for (var ride in model.data!) {
          if (ride.rideType == 'schedule_ride') {
            if (ride.statut == "pending" || ride.statut == "new" || ride.statut == "on ride" || ride.statut == "confirmed") {
              log("newRideList :: ${ride.statut} :: ${ride.id}");
              newRideList.add(ride);
            } else if (ride.statut == "completed") {
              completedRideList.add(ride);
            } else if (ride.statut == "rejected") {
              rejectedRideList.add(ride);
            }
          }
        }
        update();
        ShowToastDialog.closeLoader();
      } else {
        newRideList.clear();
        completedRideList.clear();
        rejectedRideList.clear();
        ShowToastDialog.closeLoader();
        isLoading.value = false;
      }
    } on TimeoutException {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
    } on SocketException {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
    } on Error {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
    } catch (e) {
      log('FireStoreUtils.getCurrencys Parse error $e');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }
}
