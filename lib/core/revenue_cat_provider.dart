import 'package:flutter/cupertino.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatProvider extends ChangeNotifier {
  RevenueCatProvider() {
    _init();
  }

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> _init() async {
    Purchases.addPurchaserInfoUpdateListener((purchaserInfo) async {
      updatePurchaseStatus();
    });
    updatePurchaseStatus();
  }

  Future updatePurchaseStatus() async {
    final purchaserInfo = await Purchases.getPurchaserInfo();
    final entitlements = purchaserInfo.entitlements.active.values.toList();
    _isPremium = entitlements.isNotEmpty;
    notifyListeners();
  }
}
