import 'package:flutter/material.dart';

// Logo widget'ı
class WalletLogo extends StatelessWidget {
  const WalletLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.account_balance_wallet,
      color: Theme.of(context).colorScheme.primary,
      size: 28,
    );
  }
}
