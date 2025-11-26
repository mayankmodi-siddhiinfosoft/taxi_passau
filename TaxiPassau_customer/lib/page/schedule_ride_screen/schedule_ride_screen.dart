import 'package:taxipassau/constant/constant.dart';
import 'package:taxipassau/constant/show_toast_dialog.dart';
import 'package:taxipassau/controller/dash_board_controller.dart';
import 'package:taxipassau/controller/new_ride_controller.dart';
import 'package:taxipassau/model/ride_model.dart';
import 'package:taxipassau/page/complaint/add_complaint_screen.dart';
import 'package:taxipassau/page/completed_ride_screens/trip_history_screen.dart';
import 'package:taxipassau/page/review_screens/add_review_screen.dart';
import 'package:taxipassau/themes/appbar_cust.dart';
import 'package:taxipassau/themes/button_them.dart';
import 'package:taxipassau/themes/constant_colors.dart';
import 'package:taxipassau/themes/responsive.dart';
import 'package:taxipassau/utils/dark_theme_provider.dart';
import 'package:taxipassau/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:text_scroll/text_scroll.dart';

import '../../controller/schedule_ride_controller.dart';

class ScheduleRideScreen extends StatelessWidget {
  const ScheduleRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder<ScheduleRideController>(
      init: ScheduleRideController(),
      builder: (controller) {
        return Scaffold(
            appBar: CustomAppbar(
              bgColor: AppThemeData.primary200,
              title: 'Schedule Rides'.tr,
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: AppThemeData.primary200,
                      ),
                    ),
                    Expanded(
                        flex: 10,
                        child: Container(
                          color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                        )),
                  ],
                ),
              ],
            ));
      },
    );
  }
}
