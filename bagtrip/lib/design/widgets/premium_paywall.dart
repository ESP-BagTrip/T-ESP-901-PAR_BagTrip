import 'package:bagtrip/design/widgets/premium_cta_button.dart';
import 'package:bagtrip/service/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumPaywall extends StatefulWidget {
  const PremiumPaywall({super.key});

  @override
  State<PremiumPaywall> createState() => _PremiumPaywallState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PremiumPaywall(),
    );
  }
}

class _PremiumPaywallState extends State<PremiumPaywall> {
  bool _isLoading = false;
  final _subscriptionService = SubscriptionService();

  Future<void> _handleUpgrade() async {
    setState(() => _isLoading = true);
    try {
      final url = await _subscriptionService.getCheckoutUrl();
      if (url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.workspace_premium,
            size: 48,
            color: Color(0xFFFFB800),
          ),
          const SizedBox(height: 16),
          Text(
            'Passez \u00e0 Premium',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeature('G\u00e9n\u00e9rations IA illimit\u00e9es'),
          _buildFeature('Jusqu\'\u00e0 10 viewers par trip'),
          _buildFeature('Notifications hors-ligne'),
          _buildFeature('Suggestions post-voyage IA'),
          const SizedBox(height: 24),
          PremiumCtaButton(
            label: 'Passer \u00e0 Premium - 9,99\u20AC/mois',
            onPressed: _handleUpgrade,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
