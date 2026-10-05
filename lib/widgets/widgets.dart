import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

String rupiah(num v) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

String rupiahShort(num v) {
  if (v >= 1e12) return 'Rp ${(v / 1e12).toStringAsFixed(1)} T';
  if (v >= 1e9) return 'Rp ${(v / 1e9).toStringAsFixed(1)} M';
  if (v >= 1e6) return 'Rp ${(v / 1e6).toStringAsFixed(1)} Jt';
  return rupiah(v);
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.text,
      behavior: SnackBarBehavior.floating,
    ));
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.primary,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: const StadiumBorder(),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
                ],
              ),
      ),
    );
  }
}

class OutlineTealButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const OutlineTealButton({super.key, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.teal, width: 1.5),
          foregroundColor: AppColors.tealDark,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class DeltaBadge extends StatelessWidget {
  final double pct;
  const DeltaBadge(this.pct, {super.key});

  @override
  Widget build(BuildContext context) {
    final up = pct >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: up ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '${up ? '▲' : '▼'} ${up ? '+' : ''}${pct.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: up ? AppColors.successText : AppColors.dangerText,
        ),
      ),
    );
  }
}

class CoinAvatar extends StatelessWidget {
  final String symbol;
  final double size;
  const CoinAvatar(this.symbol, {super.key, this.size = 40});

  static const _glyph = {'BTC': '₿', 'ETH': 'Ξ', 'SOL': '◎', 'XRP': '✕', 'DOGE': 'Ð'};

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _glyph[symbol] ?? symbol.substring(0, 1),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Tombol bundar kecil untuk header halaman (mis. ikon notifikasi).
class IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  const IconBubble(this.icon, {super.key, this.color = AppColors.primary, this.bg = AppColors.tealSoft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color),
    );
  }
}
