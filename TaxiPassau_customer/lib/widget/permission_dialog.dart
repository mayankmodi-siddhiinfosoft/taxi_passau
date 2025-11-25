import 'package:taxipassau/constant/show_toast_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';

class LocationPermissionDisclosureDialog extends StatelessWidget {
  const LocationPermissionDisclosureDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Location Access Disclosure'.tr),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'We need access to your location to assign for booking feature.'.tr,
            ),
            SizedBox(height: 10),
            Text(
              'This information will only be used for booking purpose and will not be shared with any third parties.'.tr,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        MaterialButton(
          onPressed: () {
            _requestLocationPermission();
          },
          child: Text(
            'Accept'.tr,
            style: TextStyle(color: Colors.green),
          ),
        ),
        MaterialButton(
          onPressed: () {
            SystemNavigator.pop();
          },
          child: Text('Decline'.tr, style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  // Method to request location permission using permission_handler package
  void _requestLocationPermission() async {
    PermissionStatus location = await Location().requestPermission();
    if (location == PermissionStatus.granted) {
      Get.back();
    } else {
      ShowToastDialog.showToast("Permission Denied");
    }
  }
}
