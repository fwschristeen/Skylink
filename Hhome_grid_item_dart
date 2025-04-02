import 'package:drone_user_app/utils/text_utils.dart';
import 'package:flutter/material.dart';

class HomeGridItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback onTap;

  const HomeGridItem({
    super.key,
    required this.imagePath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 150,
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withAlpha(50)),
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            opacity: 0.6,
          ),
        ),

        child: Center(
          child: Text(
            title,
            style: TextUtils.kSubHeading(context).copyWith(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
