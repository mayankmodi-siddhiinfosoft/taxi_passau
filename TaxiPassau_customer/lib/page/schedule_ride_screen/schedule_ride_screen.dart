import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controller/dash_board_controller.dart';
import '../../controller/schedule_ride_controller.dart';
import '../../themes/appbar_cust.dart';
import '../../themes/constant_colors.dart';
import '../../utils/dark_theme_provider.dart';
import '../completed_ride_screens/trip_history_screen.dart';
import 'package:taxipassau/model/schedule_ride_model.dart' as rd;

class ScheduleRideScreen extends StatelessWidget {
  const ScheduleRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final dashboardController = Get.find<DashBoardController>();
    return GetBuilder<ScheduleRideController>(
      init: ScheduleRideController(),
      builder: (controller) {
        List<rd.RideData> rides = controller.getRidesByDate(controller.selectedDay);
        return Scaffold(
          appBar: CustomAppbar(
            bgColor: AppThemeData.primary200,
            title: 'Schedule Rides'.tr,
          ),
          body: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2035),
                focusedDay: controller.focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, controller.selectedDay),
                calendarFormat: CalendarFormat.month,
                eventLoader: (d) => controller.getEvents(d),
                onDaySelected: controller.onDaySelected,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppThemeData.primary200,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: rides.isEmpty
                    ? const Center(child: Text("No Rides Scheduled", style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                        itemCount: rides.length,
                        itemBuilder: (_, index) {
                          rd.RideData ride = rides[index];
                          return Card(
                            color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.local_taxi, color: Colors.blue),
                              title: Text(
                                ride.destinationName!,
                                maxLines: 1,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                "${ride.statut} - "
                                "${ride.scheduleDateTime != null ? ride.scheduleDateTime!.hour.toString().padLeft(2, '0') : '--'}:"
                                "${ride.scheduleDateTime != null ? ride.scheduleDateTime!.minute.toString().padLeft(2, '0') : '--'}",
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                Get.snackbar(
                                  "Ride Details",
                                  "${ride.pickupDate} → ${ride.destinationName}",
                                );
                                await Get.to(
                                    TripHistoryScreen(
                                      initialService: dashboardController.selectedService.value,
                                    ),
                                    arguments: {
                                      "rideData": ride,
                                    })?.then((v) {
                                  controller.fetchScheduledRides();
                                });
                              },
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        );
      },
    );
  }
}
