import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/repositories.dart';

class DeviceConnectionMonitor implements ConnectionMonitor {
  final Connectivity _connectivity = Connectivity();

  @override
  Stream<bool> get changes => _connectivity.onConnectivityChanged
      .map((values) => !values.contains(ConnectivityResult.none)).distinct();

  @override
  Future<bool> get isOnline async =>
      !(await _connectivity.checkConnectivity()).contains(ConnectivityResult.none);

  @override
  Future<void> dispose() async {}
}
