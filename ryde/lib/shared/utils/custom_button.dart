import 'package:flutter/material.dart';
import 'package:ryde/core/constants/app_colors.dart';

import 'custom_text.dart';

class CustomButton extends StatelessWidget {
  final String buttonName;
  final double? height;
  final double? width;
  final double? borderRadius;
  final Color? buttonColor;
  final Color? textColor;
  final double? textSize;
  final Function()? onTap;
  final bool? isLoader;
  final bool? isBorder;
  final Border? border;
  const CustomButton({
    super.key,
    required this.buttonName,
    this.height,
    this.width,
    this.borderRadius,
    this.buttonColor,
    this.textColor,
    this.textSize,
    this.border,
    this.onTap,
    this.isLoader = false,
    this.isBorder,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return InkWell(
      onTap: (isLoader != null && !isLoader!) ? onTap : null,
      child: Container(
        height: height ?? size.width * 0.1,
        width: width ?? size.width * 0.5,
        decoration: BoxDecoration(
          border: (isBorder != null && isBorder!)
              ? Border.all(color: AppColors.buttonColor)
              : border,
          color: buttonColor ?? AppColors.buttonColor,
          borderRadius: BorderRadius.circular(borderRadius ?? 5),
        ),
        child: Center(
          child: !isLoader!
              ? MyText(
                  text: buttonName,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  //textStyle: AppTextStyle.boldStyle().copyWith(
                  //  color: textColor ?? AppColors.buttonTextColor,
                  //  fontSize: textSize ?? 16,
                  //),
                )
              : SizedBox(
                  height: size.width * 0.05,
                  width: size.width * 0.05,
                  child: const Loader(color: AppColors.buttonTextColor),
                ),
        ),
      ),
    );
  }
}

class Loader extends StatelessWidget {
  final Color color;
  const Loader({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(color),
      strokeWidth: 2.0,
    );
  }
}
