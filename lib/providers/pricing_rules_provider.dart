import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pricing_rules_repository.dart';
import '../models/pricing_rule.dart';

final pricingRulesProvider =
    AsyncNotifierProvider<PricingRulesNotifier, List<PricingRule>>(
      PricingRulesNotifier.new,
    );

class PricingRulesNotifier extends AsyncNotifier<List<PricingRule>> {
  @override
  Future<List<PricingRule>> build() {
    return ref.read(pricingRulesRepositoryProvider).list();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
