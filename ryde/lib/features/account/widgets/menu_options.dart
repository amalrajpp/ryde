// Lightweight copy of MenuOptions for the account module (uses dummy/static data)
import 'package:flutter/material.dart';
import 'package:ryde/core/constants/app_colors.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class ModuleMenuOptions extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final String? imagePath;

  const ModuleMenuOptions({
    super.key,
    this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading icon or image constrained to a fixed box to avoid layout overflow
              if (icon != null)
                Padding(
                  padding: EdgeInsets.only(right: size.width * 0.02),
                  child: Icon(icon, color: Theme.of(context).primaryColorDark),
                ),

              if (imagePath != null)
                Padding(
                  padding: EdgeInsets.only(right: size.width * 0.03),
                  child: SizedBox(
                    height: size.width * 0.06,
                    width: size.width * 0.06,
                    child: Builder(
                      builder: (ctx) {
                        final path = imagePath!;
                        if (path.startsWith('http') ||
                            path.startsWith('https')) {
                          return Image.network(
                            path,
                            height: size.width * 0.06,
                            width: size.width * 0.06,
                            fit: BoxFit.cover,
                            // If network image fails, show a simple icon placeholder
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: size.width * 0.06,
                              color: Theme.of(context).primaryColorDark,
                            ),
                          );
                        }

                        // Local asset
                        return Image.asset(
                          path,
                          height: size.width * 0.06,
                          width: size.width * 0.06,
                          color: Theme.of(context).primaryColorDark,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported,
                            size: size.width * 0.06,
                            color: Theme.of(context).primaryColorDark,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              SizedBox(width: size.width * 0.01),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: label,
                      textStyle: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 14),
                      maxLines: 1,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      MyText(
                        text: subtitle!,
                        textStyle: Theme.of(
                          context,
                        ).textTheme.bodySmall!.copyWith(fontSize: 11),
                        maxLines: 1,
                      ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: AppColors.hintColor),
            ],
          ),
          SizedBox(height: size.width * 0.05),
        ],
      ),
    );
  }
}
