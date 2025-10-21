import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class CurrencyToolPage extends StatefulWidget {
  const CurrencyToolPage({super.key});

  @override
  State<CurrencyToolPage> createState() => _CurrencyToolPageState();
}

class _CurrencyToolPageState extends State<CurrencyToolPage> {
  final usdController = TextEditingController();
  final sypController = TextEditingController();
  final rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    rateController.text = '';
    usdController.addListener(_recomputeFromUsd);
    sypController.addListener(_recomputeFromSyp);
  }

  @override
  void dispose() {
    usdController.dispose();
    sypController.dispose();
    rateController.dispose();
    super.dispose();
  }

  bool _isComputing = false;

  void _recomputeFromUsd() {
    if (_isComputing) return;
    _isComputing = true;
    final rate = double.tryParse(rateController.text.trim());
    final usd = double.tryParse(usdController.text.trim());
    if (rate != null && usd != null) {
      sypController.text = (rate * usd).toStringAsFixed(0);
    }
    _isComputing = false;
  }

  void _recomputeFromSyp() {
    if (_isComputing) return;
    _isComputing = true;
    final rate = double.tryParse(rateController.text.trim());
    final syp = double.tryParse(sypController.text.trim());
    if (rate != null && syp != null && rate != 0) {
      usdController.text = (syp / rate).toStringAsFixed(2);
    }
    _isComputing = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: rateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.translate('usd_syp_rate')),
          onChanged: (_) {
            _recomputeFromUsd();
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: usdController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.translate('usd')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: sypController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.translate('syp')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


