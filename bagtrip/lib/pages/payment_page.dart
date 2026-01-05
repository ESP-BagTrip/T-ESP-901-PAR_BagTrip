import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  static const routePath = '/payment';

  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: const Center(child: Text('Page de paiement (Stripe Integration)')),
    );
  }
}
