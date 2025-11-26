import 'dart:convert';
import 'package:get/get.dart';
import '../constant/logdata.dart';
import '../constant/show_toast_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../model/schedule_ride_model.dart' as rd;
import '../service/api.dart';
import '../utils/Preferences.dart';


class ScheduleRideController extends GetxController {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  var isLoading = false.obs;

  var scheduledRides = <rd.RideData>[].obs;

  @override
  void onInit() {
    fetchScheduledRides();
    super.onInit();
  }

  /// Fetch rides from API
  Future<void> fetchScheduledRides() async {
    try {
      isLoading.value = true;
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(
        Uri.parse("${API.scheduleRide}"),
        headers: API.header,
        body: jsonEncode({"customer_id": Preferences.getInt(Preferences.userId)}),
      );

      showLog("API :: URL :: ${API.scheduleRide} ");
      showLog("API :: Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['success'] == true) {
          List ridesList = body['rides'];
          scheduledRides.value = ridesList.map((e) => rd.RideData.fromJson(e)).toList();
          ShowToastDialog.closeLoader();
        } else {
          Get.snackbar("Error", "Failed to fetch rides");
        }
      } else {
        Get.snackbar("Error", "API Error: ${response.statusCode}");
      }
    } on SocketException {
      Get.snackbar("Error", "No Internet connection");
    } on HttpException {
      Get.snackbar("Error", "Couldn't find the resource");
    } on FormatException {
      Get.snackbar("Error", "Bad response format");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
    }
  }

  /// Get rides for selected date
  List<rd.RideData> getRidesByDate(DateTime date) {
    return scheduledRides.where((ride) {
      final rideDateTime = ride.scheduleDateTime;
      if (rideDateTime == null) return false;
      return rideDateTime.year == date.year &&
          rideDateTime.month == date.month &&
          rideDateTime.day == date.day;
    }).toList();
  }

  /// Events for calendar
  List<rd.RideData> getEvents(DateTime date) => getRidesByDate(date);

  /// Calendar date selection
  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay = selected;
    focusedDay = focused;
    update();
  }
}
