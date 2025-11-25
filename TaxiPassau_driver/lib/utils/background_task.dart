import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:taxipassau_driver/service/api.dart';
import 'package:taxipassau_driver/utils/Preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:taxipassau_driver/constant/constant.dart';

const backgroundTaskName = "updateDriverLocation";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == backgroundTaskName) {
        print("🚕 Running background driver location update...");

        // Initialize location
        final location = Location();
        bool serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) return false;
        }

        PermissionStatus permissionGranted = await location.hasPermission();
        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await location.requestPermission();
          if (permissionGranted != PermissionStatus.granted) return false;
        }

        final currentLocation = await location.getLocation();

        // Reverse geocoding → address string
        String address = '';
        try {
          final placemarks = await geocoding.placemarkFromCoordinates(
            currentLocation.latitude ?? 0.0,
            currentLocation.longitude ?? 0.0,
          );
          final p = placemarks.first;
          address = [
            p.street,
            p.locality,
            p.administrativeArea,
            p.country
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        } catch (e) {
          print("⚠️ Address lookup failed: $e");
        }

        // Retrieve driver info
        final driverId = Preferences.getString(Preferences.userId);
        final token = Preferences.getString(Preferences.accesstoken);

        if (driverId.isEmpty || token.isEmpty) {
          print("⚠️ Missing driver credentials — skipping update.");
          return true;
        }

        // Prepare request body
        final body = {
          "driver_id": driverId,
          "lat": currentLocation.latitude.toString(),
          "lng": currentLocation.longitude.toString(),
          "address": address,
        };

        print("📡 Sending driver location update: $body");

        // Send POST request
        final response = await http.post(
          Uri.parse(API.driverLocationUpdate),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          print("✅ Driver location updated successfully!");
        } else {
          print("❌ Failed to update location: ${response.body}");
        }
      }
    } catch (e) {
      print("❌ Background task error: $e");
    }

    return true;
  });
}
