import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:text_scroll/text_scroll.dart';
import '../../constant/constant.dart';
import '../../constant/show_toast_dialog.dart';
import '../../controller/schedule_ride_controller.dart';
import '../../model/ride_model.dart';
import '../../themes/button_them.dart';
import '../../themes/constant_colors.dart';
import '../../themes/custom_alert_dialog.dart';
import '../../themes/custom_dialog_box.dart';
import '../../themes/custom_widget.dart';
import '../../themes/text_field_them.dart';
import '../../utils/Preferences.dart';
import '../../utils/dark_theme_provider.dart';
import '../../widget/StarRating.dart';
import '../chats_screen/conversation_screen.dart';
import '../complaint/add_complaint_screen.dart';
import '../completed/trip_history_screen.dart';
import '../review_screens/add_review_screen.dart';
import '../route_view_screen/route_osm_view_screen.dart';
import '../route_view_screen/route_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pinput/pinput.dart';
import 'package:url_launcher/url_launcher.dart';

class ScheduleRideScreen extends StatelessWidget {
  ScheduleRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder<ScheduleRideController>(
      init: ScheduleRideController(),
      builder: (controller) {
        List<RideData> rides = controller.getRidesByDate(controller.selectedDay);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
            title: Text('Schedule Rides'.tr),
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
                child: Container(
                  // margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: false,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorColor: AppThemeData.primary200,
                          labelPadding: const EdgeInsets.symmetric(vertical: 8),
                          dividerColor: Colors.transparent,
                          labelColor: AppThemeData.primary200,
                          labelStyle: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 16,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontFamily: AppThemeData.regular,
                            fontSize: 16,
                            color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey400,
                          ),
                          tabs: [
                            Tab(text: 'New'.tr),
                            Tab(text: 'Completed'.tr),
                            Tab(text: 'Rejected'.tr),
                          ],
                        ),
                        Obx(
                          () => Expanded(
                            child: TabBarView(
                              children: [
                                buildRideTab(
                                  isLoading: controller.isLoading.value,
                                  list: controller.newRideList,
                                  emptyText: "You don't have any ride booked.",
                                  controller: controller,
                                  theme: themeChange.getThem(),
                                ),
                                buildRideTab(
                                  isLoading: controller.isLoading.value,
                                  list: controller.completedRideList,
                                  emptyText: "You have not completed any trip.",
                                  controller: controller,
                                  theme: themeChange.getThem(),
                                ),
                                buildRideTab(
                                  isLoading: controller.isLoading.value,
                                  list: controller.rejectedRideList,
                                  emptyText: "You have not rejected any trip.",
                                  controller: controller,
                                  theme: themeChange.getThem(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildRideTab({
    required bool isLoading,
    required List list,
    required String emptyText,
    required controller,
    required bool theme,
  }) {
    return RefreshIndicator(
      backgroundColor: AppThemeData.primary200,
      onRefresh: () => controller.getNewRide(),
      child: isLoading
          ? const SizedBox()
          : list.isEmpty
              ? Constant.emptyView(emptyText)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 50, left: 10, right: 10, top: 10),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return newRideWidgets(
                      context,
                      list[index],
                      controller,
                      theme,
                    );
                  },
                ),
    );
  }

  Widget newRideWidgets(BuildContext context, RideData data, ScheduleRideController controller, bool isDarkMode) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return InkWell(
      onTap: () async {
        if (data.statut == "completed") {
          var isDone = await Get.to(const TripHistoryScreen(), arguments: {"rideData": data});
          if (isDone != null) {
            await controller.getNewRide();
          }
        } else {
          var argumentData = {'type': data.statut, 'data': data};

          if (Constant.liveTrackingMapType == "inappmap") {
            if (Constant.selectedMapType == 'osm') {
              Get.to(const RouteOsmViewScreen(), arguments: argumentData);
            } else {
              Get.to(const RouteViewScreen(), arguments: argumentData);
            }
          } else {
            Constant.redirectMap(
              latitude: double.parse(data.latitudeArrivee!), //orderModel.destinationLocationLAtLng!.latitude!,
              longLatitude: double.parse(data.longitudeArrivee!), //orderModel.destinationLocationLAtLng!.longitude!,
              name: data.destinationName!,
            ); //orderModel.destinationLocationName.toString());
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            border: Border.all(
              color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey400, // ← आपकी पसंद का color
              width: 1.2, // ← border thickness
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          SvgPicture.asset("assets/icons/ic_source.svg", height: 24),
                          Image.asset("assets/icons/line.png", height: 30, color: AppThemeData.grey400),
                        ],
                      ),
                      const SizedBox(width: 5),
                      Expanded(child: Text(data.departName.toString().tr, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      SizedBox(width: 8),
                      Container(
                        width: 120,
                        height: 34,
                        decoration: BoxDecoration(color: Constant.statusColor(data), borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                            Constant().capitalizeWords(data.statut.toString()).tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Constant.statusTextColor(data), fontSize: 14, fontFamily: AppThemeData.medium),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.stops!.length,
                    itemBuilder: (context, int index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Text(String.fromCharCode(index + 65), style: const TextStyle(fontSize: 16)),
                              Image.asset("assets/icons/line.png", height: 30, color: ConstantColors.hintTextColor),
                            ],
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(data.stops![index].location.toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset("assets/icons/ic_destenation.svg", height: 24),
                      const SizedBox(width: 5),
                      Expanded(child: Text(data.destinationName.toString().tr, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: dividerCust(isDarkMode: themeChange.getThem()),
                ),
                // Padding(
                //   padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                //   child: Row(
                //     children: [
                //       Expanded(
                //         child: Column(
                //           children: [
                //             TextScroll(
                //               '${double.parse(data.distance.toString()).toStringAsFixed(int.parse(Constant.decimal!))} ${Constant.distanceUnit}',
                //               mode: TextScrollMode.bouncing,
                //               pauseBetween: const Duration(seconds: 2),
                //               style: TextStyle(color: AppThemeData.primary400, fontSize: 18, fontFamily: AppThemeData.semiBold),
                //             ),
                //             Text(
                //               "Distance".tr,
                //               style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontSize: 12, fontFamily: AppThemeData.regular),
                //             ),
                //           ],
                //         ),
                //       ),
                //       if (Constant.taxiVehicleCategoryId != data.tripCategory) const SizedBox(width: 10),
                //       if (Constant.taxiVehicleCategoryId != data.tripCategory)
                //         Expanded(
                //           child: Column(
                //             children: [
                //               Text(
                //                 data.numberPoeple.toString(),
                //                 style: TextStyle(color: AppThemeData.primary400, fontSize: 18, fontFamily: AppThemeData.semiBold),
                //               ),
                //               Text(
                //                 "Passangers".tr,
                //                 style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontSize: 12, fontFamily: AppThemeData.regular),
                //               ),
                //             ],
                //           ),
                //         ),
                //       const SizedBox(width: 10),
                //       Expanded(
                //         child: Column(
                //           children: [
                //             TextScroll(
                //               data.duree.toString(),
                //               mode: TextScrollMode.bouncing,
                //               pauseBetween: const Duration(seconds: 2),
                //               style: TextStyle(color: AppThemeData.primary400, fontSize: 18, fontFamily: AppThemeData.semiBold),
                //             ),
                //             Text(
                //               "Duration".tr,
                //               style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontSize: 12, fontFamily: AppThemeData.regular),
                //             ),
                //           ],
                //         ),
                //       ),
                //       if (Constant.taxiVehicleCategoryId != data.tripCategory || data.montant != '0') const SizedBox(width: 10),
                //       if (Constant.taxiVehicleCategoryId != data.tripCategory || data.montant != '0')
                //         Expanded(
                //           child: Column(
                //             children: [
                //               Text(
                //                 Constant().amountShow(amount: data.montant.toString()),
                //                 style: TextStyle(color: AppThemeData.primary400, fontSize: 18, fontFamily: AppThemeData.semiBold),
                //               ),
                //               Text(
                //                 "Trip Price".tr,
                //                 style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontSize: 12, fontFamily: AppThemeData.regular),
                //               ),
                //             ],
                //           ),
                //         ),
                //     ],
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _infoColumn(title: "Distance".tr, value: "${safeDouble(data.distance).toStringAsFixed(int.parse(Constant.decimal!))} ${Constant.distanceUnit}"
                            // '${double.parse(data.distance.toString()).toStringAsFixed(int.parse(Constant.decimal!))} ${Constant.distanceUnit}',
                            ),
                        if (Constant.taxiVehicleCategoryId != data.tripCategory) _infoColumn(title: "Passengers".tr, value: data.numberPoeple.toString()),
                        _infoColumn(title: "Duration".tr, value: data.duree.toString()),
                        if (Constant.taxiVehicleCategoryId != data.tripCategory || data.montant != '0')
                          _infoColumn(title: "Trip Price".tr, value: Constant().amountShow(amount: data.montant.toString())),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: Row(
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: data.photoPath.toString(),
                          height: 45,
                          width: 45,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Constant.loader(context, isDarkMode: themeChange.getThem()),
                          errorWidget: (context, url, error) => Image.asset("assets/images/appIcon.png"),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: data.rideType! == 'driver' && data.existingUserId.toString() == "null"
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data.userInfo!.name}',
                                      style: TextStyle(
                                          color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontSize: 16, fontFamily: AppThemeData.semiBold),
                                    ),
                                    Text(
                                      '${data.userInfo!.email}',
                                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data.prenom.toString()} ${data.nom.toString()}',
                                      style: TextStyle(
                                          color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontSize: 16, fontFamily: AppThemeData.semiBold),
                                    ),
                                    StarRating(size: 18, rating: double.parse(data.moyenneDriver.toString()), color: AppThemeData.warning200),
                                  ],
                                ),
                        ),
                      ),
                      Row(
                        children: [
                          Visibility(
                            visible: data.statut == "new" || data.statut == "pending" || data.statut == "on ride" || data.statut == "confirmed",
                            child: InkWell(
                                onTap: () {
                                  Get.to(ConversationScreen(), arguments: {
                                    'receiverId': int.parse(data.idUserApp.toString()),
                                    'orderId': int.parse(data.id.toString()),
                                    'receiverName': '${data.prenom} ${data.nom}',
                                    'receiverPhoto': data.photoPath
                                  });
                                },
                                child: Image.asset(
                                  'assets/icons/chat_icon.png',
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                )),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (data.rideType! == 'driver' && data.existingUserId.toString() == "null") {
                                    Constant.makePhoneCall(data.userInfo!.phone.toString());
                                  } else {
                                    Constant.makePhoneCall(data.phone.toString());
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  shape: const CircleBorder(),
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.all(6), // <-- Splash color
                                ),
                                child: const Icon(Icons.call, color: Colors.white, size: 18),
                              ),
                              Text(data.dateRetour.toString()),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (data.statut == "completed" && (data.montant == "0" || data.montant == "" || data.montant == null) && Constant.taxiVehicleCategoryId == data.tripCategory)
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFieldWidget(
                            textInputType: TextInputType.numberWithOptions(decimal: true),
                            isBorderEnable: true,
                            prefix: IconButton(
                              onPressed: () {},
                              icon: Text(
                                "${Constant.currency}",
                                style: TextStyle(fontSize: 16, color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontFamily: AppThemeData.regular),
                              ),
                            ),
                            controller: controller.ridepriceText.value,
                            validators: (String? value) {
                              if (value!.isNotEmpty) {
                                return null;
                              } else {
                                return 'required'.tr;
                              }
                            },
                            hintText: 'Enter the Ride Price'.tr,
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 2,
                          child: ButtonThem.buildButton(
                            context,
                            title: "Sent Request".tr,
                            btnColor: AppThemeData.primary200,
                            txtColor: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            onPress: () {
                              var bodyParams = {'ride_id': data.id.toString(), 'driver_id': data.idConducteur.toString(), 'price': controller.ridepriceText.value.text};
                              controller.ridepriceText.value.clear();
                              controller.setPriceByDriver(bodyParams);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: [
                      Visibility(
                        visible: data.statut == "completed",
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ButtonThem.buildButton(
                                  context,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  title: data.statutPaiement == "yes" ? "paid".tr : "Not paid".tr,
                                  btnColor: data.statutPaiement == "yes" ? AppThemeData.success300 : AppThemeData.success300,
                                  txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                  onPress: () {},
                                ),
                              ),
                              if (data.existingUserId.toString() != "null") SizedBox(width: 10),
                              if (data.existingUserId.toString() != "null")
                                data.montant != "0" && data.statutPaiement == "pending" && data.idPaymentMethod == "5"
                                    ? Expanded(
                                        child: ButtonThem.buildButton(
                                          context,
                                          title: 'Confirm Cash Payment'.tr,
                                          btnWidthRatio: 1,
                                          btnHeight: 45,
                                          btnColor: AppThemeData.primary200,
                                          txtColor: AppThemeData.grey900,
                                          onPress: () async {
                                            showDialog(
                                              barrierColor: const Color.fromARGB(66, 20, 14, 14),
                                              context: context,
                                              builder: (context) {
                                                return CustomAlertDialog(
                                                  title: "Do you want to Confirm Cash Payment for this ride?".tr,
                                                  negativeButtonText: 'No'.tr,
                                                  positiveButtonText: 'Yes'.tr,
                                                  onPressNegative: () {
                                                    Get.back();
                                                  },
                                                  onPressPositive: () async {
                                                    ShowToastDialog.showLoader("Please wait");
                                                    Map<String, dynamic> bodyParams = {'id_ride': data.id.toString()};
                                                    await controller.confirmCashPaymentRequest(bodyParams);
                                                    ShowToastDialog.closeLoader();
                                                    Get.back();
                                                  },
                                                );
                                              },
                                            );

                                            // Get.to(const AddReviewScreen(), arguments: {
                                            //   'rideData': data,
                                            // });
                                          },
                                        ),
                                      )
                                    : Expanded(
                                        child: ButtonThem.buildButton(
                                          context,
                                          title: 'Add Review'.tr,
                                          btnWidthRatio: 1,
                                          btnHeight: 45,
                                          btnColor: AppThemeData.primary200,
                                          txtColor: AppThemeData.grey900,
                                          onPress: () async {
                                            Get.to(const AddReviewScreen(), arguments: {'rideData': data});
                                          },
                                        ),
                                      ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Visibility(
                        visible: data.statut == "completed" && data.existingUserId.toString() != "null",
                        child: ButtonThem.buildButton(
                          context,
                          title: 'Add Complaint'.tr,
                          btnHeight: 45,
                          btnColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                          txtColor: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                          onPress: () async {
                            Get.to(AddComplaintScreen(), arguments: {"isReviewScreen": false, "data": data, "ride_type": "ride"});
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Visibility(
                            visible: data.statut == "pending" || data.statut == "new" || data.statut == "confirmed" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'REJECT'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.warning200,
                                  txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                  onPress: () async {
                                    buildShowBottomSheet(context, data, controller, isDarkMode);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "pending" || data.statut == "new" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'ACCEPT'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.success300,
                                  txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                  onPress: () async {
                                    showDialog(
                                      barrierColor: Colors.black26,
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title: "Do you want to confirm this booking?".tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressPositive: () {
                                            Map<String, String> bodyParams = {
                                              'id_ride': data.id.toString(),
                                              'id_user': data.idUserApp.toString(),
                                              'driver_name': '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                              'lat_conducteur': data.latitudeDepart.toString(),
                                              'lng_conducteur': data.longitudeDepart.toString(),
                                              'lat_client': data.latitudeArrivee.toString(),
                                              'lng_client': data.longitudeArrivee.toString(),
                                              'from_id': Preferences.getInt(Preferences.userId).toString(),
                                            };

                                            controller.confirmedRide(bodyParams).then((value) {
                                              if (value != null) {
                                                data.statut = "confirmed";
                                                Get.back();
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return CustomDialogBox(
                                                      title: "Confirmed Successfully".tr,
                                                      descriptions: "Ride Successfully confirmed.".tr,
                                                      text: "Ok".tr,
                                                      onPress: () async {
                                                        ShowToastDialog.showLoader("Please wait");
                                                        await controller.getNewRide();
                                                        ShowToastDialog.closeLoader();
                                                        Get.back();
                                                      },
                                                      img: Image.asset('assets/images/green_checked.png'),
                                                    );
                                                  },
                                                );
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "confirmed" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'On Ride'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.primary200,
                                  txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                  onPress: () async {
                                    showDialog(
                                      barrierColor: const Color.fromARGB(66, 20, 14, 14),
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title: "Do you want to on ride this ride?".tr,
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          onPressPositive: () {
                                            Get.back();

                                            /// 🔥 SCHEDULE VALIDATION BLOCK
                                            if (data.rideType == "schedule_ride" &&
                                                data.scheduleDateTime != null) {
                                              DateTime now = DateTime.now();
                                              DateTime scheduleTime = data.scheduleDateTime!;

                                              if (scheduleTime.isAfter(now)) {
                                                ShowToastDialog.showToast(
                                                  "This ride is scheduled. You can start only at: ${scheduleTime.toString()}",
                                                );
                                                return;
                                              }
                                            }

                                            if (Constant.rideOtp.toString() != 'yes' || data.rideType! == 'driver') {
                                              Map<String, String> bodyParams = {
                                                'id_ride': data.id.toString(),
                                                'id_user': data.idUserApp.toString(),
                                                'use_name': '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                                'from_id': Preferences.getInt(Preferences.userId).toString(),
                                              };
                                              controller.setOnRideRequest(bodyParams).then((value) async {
                                                await controller.getNewRide();
                                                if (value != null) {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return CustomDialogBox(
                                                        title: "On ride Successfully".tr,
                                                        descriptions: "Ride Successfully On ride.".tr,
                                                        text: "Ok".tr,
                                                        onPress: () async {
                                                          ShowToastDialog.showLoader("Please wait");
                                                          await controller.getNewRide();
                                                          ShowToastDialog.closeLoader();
                                                          Get.back();
                                                        },
                                                        img: Image.asset('assets/images/green_checked.png'),
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  Get.back();
                                                }
                                              });
                                            } else {
                                              controller.otpController = TextEditingController();
                                              showDialog(
                                                barrierColor: Colors.black26,
                                                context: context,
                                                builder: (context) {
                                                  return Dialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                    elevation: 0,
                                                    backgroundColor: Colors.transparent,
                                                    child: Container(
                                                      height: 200,
                                                      padding: const EdgeInsets.only(left: 10, top: 20, right: 10, bottom: 20),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.rectangle,
                                                        color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                                        borderRadius: BorderRadius.circular(20),
                                                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 10), blurRadius: 10)],
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Text("Enter OTP".tr, style: TextStyle(fontSize: 16)),
                                                          const SizedBox(height: 20),
                                                          Pinput(
                                                            controller: controller.otpController,
                                                            defaultPinTheme: PinTheme(
                                                              height: 50,
                                                              width: 50,
                                                              textStyle: const TextStyle(letterSpacing: 0.60, fontSize: 16),
                                                              // margin: EdgeInsets.all(10),
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(10),
                                                                shape: BoxShape.rectangle,
                                                                color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                                                border: Border.all(color: AppThemeData.textFieldBoarderColor, width: 0.7),
                                                              ),
                                                            ),
                                                            keyboardType: TextInputType.phone,
                                                            textInputAction: TextInputAction.done,
                                                            length: 6,
                                                          ),
                                                          const SizedBox(height: 16),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: ButtonThem.buildButton(
                                                                  context,
                                                                  title: 'done'.tr,
                                                                  btnHeight: 45,
                                                                  btnWidthRatio: 1,
                                                                  btnColor: AppThemeData.primary200,
                                                                  txtColor: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                                  onPress: () {
                                                                    if (controller.otpController.text.toString().length == 6) {
                                                                      controller.verifyOTP(userId: data.idUserApp!.toString(), rideId: data.id!.toString()).then((value) {
                                                                        if (value != null && value['success'] == "success") {
                                                                          Map<String, String> bodyParams = {
                                                                            'id_ride': data.id.toString(),
                                                                            'id_user': data.idUserApp.toString(),
                                                                            'use_name': '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                                                            'from_id': Preferences.getInt(Preferences.userId).toString(),
                                                                          };
                                                                          controller.setOnRideRequest(bodyParams).then((value) {
                                                                            if (value != null) {
                                                                              Get.back();
                                                                              showDialog(
                                                                                context: context,
                                                                                builder: (BuildContext context) {
                                                                                  return CustomDialogBox(
                                                                                    title: "On ride Successfully".tr,
                                                                                    descriptions: "Ride Successfully On ride.".tr,
                                                                                    text: "Ok".tr,
                                                                                    onPress: () async {
                                                                                      ShowToastDialog.showLoader("Please wait");
                                                                                      await controller.getNewRide();
                                                                                      ShowToastDialog.closeLoader();
                                                                                      Get.back();
                                                                                    },
                                                                                    img: Image.asset('assets/images/green_checked.png'),
                                                                                  );
                                                                                },
                                                                              );
                                                                            }
                                                                          });
                                                                        }
                                                                      });
                                                                    } else {
                                                                      ShowToastDialog.showToast('Please Enter OTP');
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Expanded(
                                                                child: ButtonThem.buildBorderButton(
                                                                  context,
                                                                  title: 'cancel'.tr,
                                                                  btnHeight: 45,
                                                                  btnWidthRatio: 1,
                                                                  btnColor: isDarkMode ? AppThemeData.grey800 : AppThemeData.grey100,
                                                                  txtColor: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                                  btnBorderColor: isDarkMode ? AppThemeData.grey800 : AppThemeData.grey100,
                                                                  onPress: () {
                                                                    Get.back();
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }
                                            // if (data.carDriverConfirmed == 1) {
                                            //
                                            // } else if (data.carDriverConfirmed == 2) {
                                            //   Get.back();
                                            //   ShowToastDialog.showToast("Customer decline the confirmation of driver and car information.");
                                            // } else if (data.carDriverConfirmed == 0) {
                                            //   Get.back();
                                            //   ShowToastDialog.showToast("Customer needs to verify driver and car before you can start trip.");
                                            // }
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "on ride" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'START RIDE'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.secondary200,
                                  txtColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900,
                                  onPress: () async {
                                    String googleUrl =
                                        'https://www.google.com/maps/search/?api=1&query=${double.parse(data.latitudeArrivee.toString())},${double.parse(data.longitudeArrivee.toString())}';
                                    if (await canLaunch(googleUrl)) {
                                      await launch(googleUrl);
                                    } else {
                                      throw 'Could not open the map.';
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "on ride" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'COMPLETE'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.success300,
                                  txtColor: isDarkMode ? AppThemeData.surface50 : AppThemeData.surface50,
                                  onPress: () async {
                                    showDialog(
                                      barrierColor: Colors.black26,
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title: "Do you want to complete this ride?".tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressPositive: () {
                                            Map<String, String> bodyParams = {
                                              'id_ride': data.id.toString(),
                                              'id_user': data.idUserApp.toString(),
                                              'driver_name': '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                              'from_id': Preferences.getInt(Preferences.userId).toString(),
                                            };
                                            controller.setCompletedRequest(bodyParams, data).then((value) {
                                              if (value != null) {
                                                Get.back();
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return CustomDialogBox(
                                                      title: "Completed Successfully".tr,
                                                      descriptions: "Ride Successfully completed.".tr,
                                                      text: "Ok".tr,
                                                      onPress: () async {
                                                        ShowToastDialog.showLoader("Please wait");
                                                        await controller.getNewRide();
                                                        ShowToastDialog.closeLoader();
                                                        Get.back();
                                                      },
                                                      img: Image.asset('assets/images/green_checked.png'),
                                                    );
                                                  },
                                                );
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final resonController = TextEditingController();

  buildShowBottomSheet(BuildContext context, RideData data, ScheduleRideController controller, bool isDarkMode) {
    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15)),
      ),
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text("Cancel Trip".tr, style: const TextStyle(fontSize: 18)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text("Write a reason for trip cancellation".tr, style: TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: resonController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 1.0)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 1.0)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: ButtonThem.buildButton(
                                context,
                                title: 'Cancel Trip'.tr,
                                btnHeight: 45,
                                btnWidthRatio: 0.8,
                                btnColor: AppThemeData.primary200,
                                txtColor: !isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                onPress: () async {
                                  if (resonController.text.isNotEmpty) {
                                    Get.back();
                                    showDialog(
                                      barrierColor: Colors.black26,
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title: "Do you want to reject this booking?".tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressPositive: () {
                                            Map<String, String> bodyParams = {
                                              'id_ride': data.id.toString(),
                                              'id_user': data.idUserApp.toString(),
                                              'name': '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                              'from_id': Preferences.getInt(Preferences.userId).toString(),
                                              'user_cat': controller.userModel.value.userData!.userCat.toString(),
                                              'reason': resonController.text.toString(),
                                            };
                                            controller.canceledRide(bodyParams).then((value) {
                                              Get.back();
                                              if (value != null) {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return CustomDialogBox(
                                                      title: "Reject Successfully".tr,
                                                      descriptions: "Ride Successfully rejected.".tr,
                                                      text: "Ok".tr,
                                                      onPress: () async {
                                                        ShowToastDialog.showLoader("Please wait");
                                                        await controller.getNewRide();
                                                        ShowToastDialog.closeLoader();
                                                        Get.back();
                                                      },
                                                      img: Image.asset('assets/images/green_checked.png'),
                                                    );
                                                  },
                                                );
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  } else {
                                    ShowToastDialog.showToast("Please enter a reason");
                                  }
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5, left: 10),
                              child: ButtonThem.buildBorderButton(
                                context,
                                title: 'Close'.tr,
                                btnHeight: 45,
                                btnWidthRatio: 0.8,
                                btnColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                txtColor: !isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                btnBorderColor: AppThemeData.primary200,
                                onPress: () async {
                                  Get.back();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double safeDouble(dynamic value) {
    if (value == null) return 0.0;

    final str = value.toString().trim();

    if (str.isEmpty || str.toLowerCase() == "null" || str.toLowerCase() == "nan" || str.toLowerCase() == "undefined") {
      return 0.0;
    }

    return double.tryParse(str) ?? 0.0;
  }

  Widget _infoColumn({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextScroll(
            value,
            mode: TextScrollMode.bouncing,
            pauseBetween: const Duration(seconds: 2),
            style: TextStyle(color: AppThemeData.primary400, fontSize: 18, fontFamily: AppThemeData.semiBold),
          ),
          Text(
            title,
            style: TextStyle(color: AppThemeData.grey900, fontSize: 12, fontFamily: AppThemeData.regular),
          ),
        ],
      ),
    );
  }
}
