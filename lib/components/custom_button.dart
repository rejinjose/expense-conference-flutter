import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, outline, ghost, danger }
enum ButtonSize { sm, md, lg }

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final Widget? leftIcon;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.isLoading = false,
    this.leftIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Determine Padding based on size
    final EdgeInsets padding = switch (size) {
      ButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ButtonSize.md => const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ButtonSize.lg => const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    };

    // Helper for Button Content
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        else if (leftIcon != null) ...[
          leftIcon!,
          const SizedBox(width: 8),
        ],
        if (!isLoading) Text(text),
      ],
    );

    // Styling based on variant
    return switch (variant) {
      ButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(padding: padding),
          child: content,
        ),
      ButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(padding: padding),
          child: content,
        ),
      ButtonVariant.danger => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            padding: padding,
          ),
          child: content,
        ),
      _ => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(padding: padding),
          child: content,
        ),
    };
  }
}
