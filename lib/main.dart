import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/routes.dart';
import 'package:drone_user_app/wrapper_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [BlocProvider(create: (context) => AuthBloc())],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Drone User App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.grey.shade800,
                primary: Colors.black,
                onPrimary: Colors.white,
                secondary: Colors.grey.shade800,
                onSecondary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
                background: Colors.white,
                onBackground: Colors.black,
                error: Colors.red.shade800,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
              cardTheme: CardTheme(
                color: Colors.white,
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shadowColor: Colors.black26,
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: const IconThemeData(color: Colors.black),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Colors.white,
                modalBackgroundColor: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: CircleBorder(),
              ),
              tabBarTheme: TabBarTheme(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.black,
                dividerColor: Colors.transparent,
              ),
              iconTheme: const IconThemeData(color: Colors.black),
              textTheme: TextTheme(
                displayLarge: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                displayMedium: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                displaySmall: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                headlineLarge: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                headlineMedium: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                headlineSmall: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                titleLarge: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                titleMedium: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                titleSmall: TextStyle(color: Colors.black),
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black),
                bodySmall: TextStyle(color: Colors.grey.shade700),
                labelLarge: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                labelMedium: TextStyle(color: Colors.black),
                labelSmall: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.grey,
                primary: Colors.white,
                onPrimary: Colors.black,
                secondary: Colors.grey.shade200,
                onSecondary: Colors.black,
                surface: Colors.black,
                onSurface: Colors.white,
                background: Colors.black,
                onBackground: Colors.white,
                error: Colors.red.shade300,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.black,
              cardTheme: CardTheme(
                color: const Color(0xFF121212),
                elevation: 2,
                shadowColor: Colors.white10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade900, width: 1),
                ),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.white10,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Color(0xFF121212),
                modalBackgroundColor: Color(0xFF121212),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 2,
                shape: CircleBorder(),
              ),
              tabBarTheme: TabBarTheme(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: Colors.white,
                dividerColor: Colors.transparent,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              textTheme: TextTheme(
                displayLarge: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                displayMedium: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                displaySmall: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                headlineLarge: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                headlineMedium: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                headlineSmall: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                titleLarge: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                titleMedium: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                titleSmall: TextStyle(color: Colors.white),
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white),
                bodySmall: TextStyle(color: Colors.grey.shade300),
                labelLarge: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                labelMedium: TextStyle(color: Colors.white),
                labelSmall: TextStyle(color: Colors.grey.shade300),
              ),
            ),
            themeMode: ThemeMode.dark,
            initialRoute: '/',
            routes: routes,
            onGenerateRoute: onGenerateRoute,
          ),
        );
      },
    );
  }
}
