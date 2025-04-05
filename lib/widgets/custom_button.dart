import 'package:drone_user_app/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final void Function() onPressed;
  final bool isSocial;
  final bool isOutlined;
  final double? height;
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSocial = false,
    this.isOutlined = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: height,
        padding: EdgeInsets.symmetric(vertical: height != null ? 0 : 16.h),
        margin: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color:
              isSocial
                  ? Theme.of(context).colorScheme.onTertiary
                  : isOutlined
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10.r),
          border:
              isOutlined
                  ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.w,
                  )
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSocial) ...[
              SvgPicture.asset(
                'assets/google_logo.svg',
                width: 32.w,
                height: 32.h,
              ),
              const SizedBox(width: 16),
            ],
            Text(
              text,
              style: TextUtils.kSubHeading(context).copyWith(
                color:
                    isSocial
                        ? Theme.of(context).colorScheme.onPrimary
                        : isOutlined
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                fontSize: 18.sp,
                fontWeight: isOutlined ? FontWeight.w600 : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
