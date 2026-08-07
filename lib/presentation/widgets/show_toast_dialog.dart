
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ShowToastDialog{
  static showToast(String? message, {EasyLoadingToastPosition position = EasyLoadingToastPosition.top}) {
    try {
      if (EasyLoading.instance.overlayEntry != null) {
        EasyLoading.showToast(message?.replaceAll("Exception:", "")??"", toastPosition: position);
      } else {
        print("Toast: $message");
      }
    } catch (e) {
      print("Toast: $message");
    }
  }

  static showLoader(String message) {
    EasyLoading.show(status: message);
  }

  static closeLoader() {
    EasyLoading.dismiss();
  }
}