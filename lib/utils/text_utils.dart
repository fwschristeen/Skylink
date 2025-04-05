import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TextUtils {
  static TextStyle kHeading(BuildContext context) => GoogleFonts.poppins(
    fontSize: 32.sp,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.primary,
  );

  static TextStyle kSubHeading(BuildContext context) => GoogleFonts.poppins(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.primary,
  );

  static TextStyle kBodyText(BuildContext context) => GoogleFonts.poppins(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.primary,
  );
}
