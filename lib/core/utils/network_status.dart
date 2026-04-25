import 'package:flutter/foundation.dart';

enum NetworkStatus { online, offline }

class NetworkStatusController {
  NetworkStatusController._();

  static final ValueNotifier<NetworkStatus> status = ValueNotifier(
    NetworkStatus.online,
  );

  static void markOnline() {
    if (status.value != NetworkStatus.online) {
      status.value = NetworkStatus.online;
    }
  }

  static void markOffline() {
    if (status.value != NetworkStatus.offline) {
      status.value = NetworkStatus.offline;
    }
  }
}
