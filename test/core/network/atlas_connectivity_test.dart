import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/network/atlas_connectivity.dart';

void main() {
  group('AtlasConnectivity.isOfflineResults', () {
    test('Airplane Mode / none → offline', () {
      expect(
        AtlasConnectivity.isOfflineResults(const [ConnectivityResult.none]),
        isTrue,
      );
    });

    test('liste vide → offline', () {
      expect(AtlasConnectivity.isOfflineResults(const []), isTrue);
    });

    test('wifi / cellular / ethernet → online', () {
      expect(
        AtlasConnectivity.isOfflineResults(const [ConnectivityResult.wifi]),
        isFalse,
      );
      expect(
        AtlasConnectivity.isOfflineResults(const [ConnectivityResult.mobile]),
        isFalse,
      );
      expect(
        AtlasConnectivity.isOfflineResults(const [
          ConnectivityResult.wifi,
          ConnectivityResult.mobile,
        ]),
        isFalse,
      );
    });
  });

  group('AtlasConnectivity', () {
    test('debugSetOffline notifie et bascule isOffline', () {
      final connectivity = AtlasConnectivity(
        interpretResults: (_) => false,
      );
      var notifications = 0;
      connectivity.addListener(() => notifications += 1);

      expect(connectivity.isOffline, isFalse);

      connectivity.debugSetOffline(true);
      expect(connectivity.isOffline, isTrue);
      expect(notifications, 1);

      connectivity.debugSetOffline(true);
      expect(notifications, 1);

      connectivity.debugSetOffline(false);
      expect(connectivity.isOffline, isFalse);
      expect(notifications, 2);

      connectivity.dispose();
    });
  });
}
