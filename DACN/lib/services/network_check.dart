import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class NetworkService {
  static Stream<bool> get connectionStream async* {
    yield* Connectivity().onConnectivityChanged.asyncMap((status) async {
      if (status == ConnectivityResult.none) return false;
      return await InternetConnectionChecker().hasConnection;
    });
  }
}
