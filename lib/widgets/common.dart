import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      Card(child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)));
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.teal),
      );
}

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.eyebrow, required this.title, required this.subtitle});
  final String eyebrow, title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(eyebrow),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppColors.muted)),
        ]),
      );
}

class IconBubble extends StatelessWidget {
  const IconBubble(this.icon, {super.key, this.color = AppColors.teal});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color.withValues(.25), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.olive, size: 22),
      );
}

Color mealColor(String name) => switch (name) {
      'peach' => AppColors.mint,
      'green' => AppColors.leaf,
      'yellow' => AppColors.lime,
      _ => AppColors.mint,
    };

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.initials, {super.key, this.radius = 20});
  final String initials;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.mint,
        child: Text(initials, style: TextStyle(fontSize: radius * .6, fontWeight: FontWeight.w800, color: AppColors.olive)),
      );
}

Color statusColor(String status) => switch (status) {
      'Atenção' => AppColors.warn,
      'Pendente' => AppColors.muted,
      _ => AppColors.teal,
    };

/// Máscara (11) 99999-9999 para campos de telefone.
class PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final all = newValue.text.replaceAll(RegExp(r'\D'), '');
    final d = all.length > 11 ? all.substring(0, 11) : all;
    String out;
    if (d.isEmpty) {
      out = '';
    } else if (d.length <= 2) {
      out = '($d';
    } else if (d.length <= 7) {
      out = '(${d.substring(0, 2)}) ${d.substring(2)}';
    } else {
      out = '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
    }
    return TextEditingValue(text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}
