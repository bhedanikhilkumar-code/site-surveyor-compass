import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PremiumButton({required this.text, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.9),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: theme.colorScheme.primary.withOpacity(0.2),
      ),
      child: Text(text, style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class PremiumTextField extends StatelessWidget {
  final String hintText;

  const PremiumTextField({required this.hintText, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: theme.colorScheme.outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface.withOpacity(0.8),
        contentPadding: EdgeInsets.all(AppSpacing.sm),
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  final Widget child;

  const PremiumCard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shadowColor: theme.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surface.withOpacity(0.95),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}