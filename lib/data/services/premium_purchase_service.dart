import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumPurchaseService extends ChangeNotifier {
  static const String lifetimeProductId = 'riskpulse_lifetime';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  ProductDetails? _lifetimeProduct;

  bool _isAvailable = false;
  bool _isPremium = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductDetails? get lifetimeProduct => _lifetimeProduct;

  PremiumPurchaseService() {
    _purchaseSubscription =
        _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (Object error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    initialize();
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(
        <String>{lifetimeProductId},
      );

      if (response.error != null) {
        _errorMessage = response.error!.message;
      }

      if (response.productDetails.isNotEmpty) {
        _lifetimeProduct = response.productDetails.first;
      }

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> purchaseLifetime() async {
    if (_lifetimeProduct == null) {
      await initialize();

      if (_lifetimeProduct == null) {
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: _lifetimeProduct!,
    );

    await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases();
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) {
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.productID != lifetimeProductId) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _isPremium = true;
          _isLoading = false;
          break;

        case PurchaseStatus.pending:
          _isLoading = true;
          break;

        case PurchaseStatus.error:
          _errorMessage =
              purchase.error?.message ?? 'Purchase failed.';
          _isLoading = false;
          break;

        case PurchaseStatus.canceled:
          _isLoading = false;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
