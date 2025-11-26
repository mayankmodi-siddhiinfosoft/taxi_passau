import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import '../constant/show_toast_dialog.dart';
import 'package:taxipassau/constant/logdata.dart';
import 'package:taxipassau/service/api.dart';
import 'package:taxipassau/utils/Preferences.dart';
import 'package:http/http.dart' as http;
import '../model/ride_model.dart';

class ScheduleRideController extends GetxController {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  var isLoading = false.obs;

  /// Store ALL rides from API
  var allRides = <RideData>[].obs;

  /// Only schedule rides
  var scheduledRides = <RideData>[].obs;

  @override
  void onInit() {
    fetchScheduledRides(isinit: true);
    super.onInit();
  }

  Future<void> fetchScheduledRides({bool isinit = false}) async {
    try {
      if (isinit) {
        ShowToastDialog.showLoader("Please wait");
      }

      final url = "${API.userAllRides}?id_user_app=${Preferences.getInt(Preferences.userId)}";
      final response = await http.get(Uri.parse(url), headers: API.header);

      showLog("API :: $url");
      showLog("Response :: ${response.statusCode}");
      showLog("Body :: ${response.body}");

      if (response.statusCode == 200) {
        Map<String, dynamic> body = json.decode(response.body);

        if (body['success'] == true) {
          RideModel model = RideModel.fromJson(body);

          /// Store ALL rides
          allRides.value = model.data ?? [];

          /// Filter schedule rides only
          scheduledRides.value = allRides.where((ride) =>
          ride.rideType != null &&
              ride.rideType == "schedule_ride" &&
              ride.scheduleDateTime != null
          ).toList();

          showLog("Total Rides: ${allRides.length}");
          showLog("Schedule Rides: ${scheduledRides.length}");
        }
      }

      ShowToastDialog.closeLoader();
      isLoading.value = false;
      update();
    } catch (e) {
      log("Error: $e");
      ShowToastDialog.closeLoader();
      isLoading.value = false;
    }
  }

  /// Filter schedule rides by selected date
  List<RideData> getRidesByDate(DateTime date) {
    return scheduledRides.where((ride) {
      DateTime? dt = ride.scheduleDateTime;
      if (dt == null) return false;
      return dt.year == date.year && dt.month == date.month && dt.day == date.day;
    }).toList();
  }

  List<RideData> getEvents(DateTime date) => getRidesByDate(date);

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay = selected;
    focusedDay = focused;
    update();
  }
}
