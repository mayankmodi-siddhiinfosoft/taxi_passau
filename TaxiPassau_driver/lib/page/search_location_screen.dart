import 'package:taxipassau_driver/controller/search_address_controller.dart';
import 'package:taxipassau_driver/themes/app_bar_custom.dart';
import 'package:taxipassau_driver/themes/text_field_them.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressSearchScreen extends StatelessWidget {
  const AddressSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX(
        init: SearchAddressController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppbarCustom(
              title: 'Search Address'.tr,
              elevation: 0,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFieldWidget(
                            onChanged: (v) {
                              controller.debouncer(() => controller.fetchAddress(v));
                              return null;
                            },
                            radius: BorderRadius.circular(8.0),
                            hintText: 'Enter address or location'.tr,
                            controller: controller.searchTxtController.value),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    primary: true,
                    itemCount: controller.suggestionsList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(controller.suggestionsList[index].address.toString()),
                        onTap: () {
                          Get.back(result: controller.suggestionsList[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }
}
