import 'package:flutter/material.dart';
import 'package:ryde/core/constants/app_colors.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class ModuleEditOptions extends StatelessWidget {
  final String text;
  final String header;
  final Function()? onTap;
  final String? imagePath;

  const ModuleEditOptions({
    super.key,
    required this.text,
    required this.header,
    this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (imagePath != null)
                    Image.asset(
                      imagePath!,
                      height: size.width * 0.06,
                      width: size.width * 0.06,
                      fit: BoxFit.contain,
                      color: AppColors.greyHintColor,
                    ),
                  SizedBox(width: size.width * 0.025),
                  SizedBox(
                    width: size.width * 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: header,
                          textStyle: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                fontSize: 14,
                                color: AppColors.greyHintColor,
                              ),
                        ),
                        const SizedBox(height: 2),
                        MyText(
                          text: text,
                          textStyle: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                color: Theme.of(context).primaryColorDark,
                                fontSize: 16,
                              ),
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 25),
      ],
    );
  }
}
