import 'package:drone_user_app/features/auth/screens/login_page.dart';
import 'package:drone_user_app/features/auth/screens/profile_screen.dart';
import 'package:drone_user_app/features/home/screens/home_page.dart';
import 'package:drone_user_app/features/marketplace/models/product_model.dart';
import 'package:drone_user_app/features/marketplace/screens/marketplace_screen.dart';
import 'package:drone_user_app/features/marketplace/screens/my_listings_screen.dart';
import 'package:drone_user_app/features/marketplace/screens/product_details_screen.dart';
import 'package:drone_user_app/features/pilots/models/pilot_model.dart';
import 'package:drone_user_app/features/pilots/screens/edit_pilot_profile_screen.dart';
import 'package:drone_user_app/features/pilots/screens/pilot_details_screen.dart';
import 'package:drone_user_app/features/pilots/screens/pilots_list_screen.dart';
import 'package:drone_user_app/features/rental/models/drone_rental_model.dart';
import 'package:drone_user_app/features/rental/screens/drone_rental_details_screen.dart';
import 'package:drone_user_app/features/rental/screens/rent_drone_screen.dart';
import 'package:drone_user_app/features/rental/screens/rent_out_screen.dart';
import 'package:drone_user_app/features/service_center/models/service_center_model.dart';
import 'package:drone_user_app/features/service_center/screens/add_service_center_screen.dart';
import 'package:drone_user_app/features/service_center/screens/edit_service_center_screen.dart';
import 'package:drone_user_app/features/service_center/screens/my_service_centers_screen.dart';
import 'package:drone_user_app/features/service_center/screens/service_center_details_screen.dart';
import 'package:drone_user_app/features/service_center/screens/service_centers_screen.dart';
import 'package:drone_user_app/features/splash/screens/splash_screen.dart';
import 'package:drone_user_app/wrapper_page.dart';
import 'package:flutter/material.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const SplashScreen(),
  '/wrapper': (context) => const WrapperPage(),
  '/login': (context) => const LoginPage(),
  '/home': (context) => const HomePage(),
  '/marketplace': (context) => const MarketplaceScreen(),
  '/rent-drone': (context) => const RentDroneScreen(),
  '/rent-out': (context) => const RentOutScreen(),
  '/service-centers': (context) => const ServiceCentersScreen(),
  '/add-service-center': (context) => const AddServiceCenterScreen(),
  '/my-listings': (context) => const MyListingsScreen(),
  '/my-service-centers': (context) => const MyServiceCentersScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/pilots': (context) => const PilotsListScreen(),
  '/edit-pilot-profile': (context) => const EditPilotProfileScreen(),
};

// Route generator for routes that need arguments
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/edit-service-center':
      final ServiceCenterModel serviceCenter =
          settings.arguments as ServiceCenterModel;
      return MaterialPageRoute(
        builder:
            (context) => EditServiceCenterScreen(serviceCenter: serviceCenter),
      );
    case '/service-center-details':
      final ServiceCenterModel serviceCenter =
          settings.arguments as ServiceCenterModel;
      return MaterialPageRoute(
        builder:
            (context) =>
                ServiceCenterDetailsScreen(serviceCenter: serviceCenter),
      );
    case '/pilot-details':
      final PilotModel pilot = settings.arguments as PilotModel;
      return MaterialPageRoute(
        builder: (context) => const PilotDetailsScreen(),
        settings: settings,
      );
    case '/product-details':
      final ProductModel product = settings.arguments as ProductModel;
      return MaterialPageRoute(
        builder: (context) => const ProductDetailsScreen(),
        settings: settings,
      );
    case '/drone-rental-details':
      final DroneRentalModel drone = settings.arguments as DroneRentalModel;
      return MaterialPageRoute(
        builder: (context) => const DroneRentalDetailsScreen(),
        settings: settings,
      );
    default:
      return null;
  }
}
