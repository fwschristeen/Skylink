import 'package:drone_user_app/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatefulWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? suffixText;
  final Function()? suffixOnClick;
  final FormFieldValidator<String>? validator;
  const CustomTextField({
    super.key,
    required this.title,
    required this.hintText,
    required this.controller,
    required this.keyboardType,
    required this.obscureText,
    this.suffixText,
    this.suffixOnClick,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool isShowPassword = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextUtils.kHeading(context).copyWith(fontSize: 18.sp),
          ),
          SizedBox(height: 8.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextFormField(
                controller: widget.controller,
                validator: widget.validator,
                keyboardType: widget.keyboardType,
                obscureText: isShowPassword ? false : widget.obscureText,
                style: TextUtils.kSubHeading(context).copyWith(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 16.sp,
                ),
                cursorColor: Theme.of(context).colorScheme.surface,
                cursorHeight: 20.h,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextUtils.kSubHeading(context).copyWith(
                    color: Theme.of(context).colorScheme.surface.withAlpha(100),
                    fontSize: 16.sp,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 8.h,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.primary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 0.w,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withAlpha(100),
                      width: 0.w,
                    ),
                  ),
                  suffixIcon:
                      widget.obscureText
                          ? Container(
                            margin: EdgeInsets.only(right: 8.w),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  isShowPassword = !isShowPassword;
                                });
                              },
                              icon:
                                  isShowPassword
                                      ? Icon(
                                        Icons.visibility_off_outlined,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                      )
                                      : Icon(
                                        Icons.visibility_outlined,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                      ),
                            ),
                          )
                          : null,
                ),
              ),
              if (widget.suffixText != null && widget.suffixText!.isNotEmpty)
                TextButton(
                  onPressed: widget.suffixOnClick,
                  child: Text(
                    widget.suffixText!,
                    style: TextUtils.kHeading(context).copyWith(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
