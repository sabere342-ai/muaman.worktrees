import 'dart:io';
import 'package:flutter/material.dart';
import '../services/shop_profile_service.dart';

/// Renders the shop logo from the central [ShopProfileService], falling back
/// to a neutral store icon when no logo is set or the logo file is missing or
/// invalid — the application must never crash because of a broken logo.
class ShopLogo extends StatelessWidget {
  const ShopLogo({
    super.key,
    this.size = 48,
    this.fallbackColor = Colors.teal,
  });

  final double size;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ShopProfileService.instance,
      builder: (context, _) {
        final logoPath = ShopProfileService.instance.current.logoPath;
        if (logoPath.isNotEmpty) {
          final file = File(logoPath);
          if (file.existsSync()) {
            return ClipOval(
              child: Image.file(
                file,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
            );
          }
        }
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return Icon(Icons.store, size: size, color: fallbackColor);
  }
}
