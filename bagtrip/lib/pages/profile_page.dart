import 'package:flutter/material.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/primary_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppSpacing.allEdgeInsetSpace24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorName.secondary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 60,
                  color: ColorName.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'Mon profil',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Gérez vos informations personnelles et vos préférences',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorName.primaryTrueDark.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: AppSpacing.space32),
              PrimaryButton(
                label: 'Modifier le profil',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
