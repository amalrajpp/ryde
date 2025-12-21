import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ryde/core/constants/app_colors.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class ModuleTopBar extends StatelessWidget {
  final String title;
  final Widget? subTitleWidget;
  final Function()? onBack;

  const ModuleTopBar({
    super.key,
    required this.title,
    this.subTitleWidget,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: SizedBox(
        height: size.width * 0.37,
        width: size.width,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          height: size.height * 0.08,
                          width: size.width * 0.08,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(height: 20),
                        ),
                      ),
                      MyText(
                        text: title,
                        textStyle: Theme.of(context).textTheme.titleLarge!
                            .copyWith(fontSize: 20, color: AppColors.white),
                      ),
                    ],
                  ),
                  if (subTitleWidget != null) subTitleWidget!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
