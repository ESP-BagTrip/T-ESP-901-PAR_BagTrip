import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvTestPage extends StatelessWidget {
  const EnvTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['API_KEY'] ?? 'Non défini';
    final apiUrl = dotenv.env['API_URL'] ?? 'Non défini';

    return Scaffold(
      appBar: AppBar(title: const Text('Test Environnement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variables d\'environnement chargées :',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _buildEnvCard('API_KEY', apiKey),
            const SizedBox(height: 10),
            _buildEnvCard('API_URL', apiUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvCard(String key, String value) {
    return Card(
      child: ListTile(
        title: Text(key),
        subtitle: Text(value),
        leading: const Icon(Icons.settings),
      ),
    );
  }
}