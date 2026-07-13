import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Controllers/payment_controller.dart';
import 'Controllers/admin_controller.dart';
import 'Controllers/auth_controller.dart';
import 'Controllers/cart_controller.dart';
import 'Controllers/coupon_controller.dart';
import 'Controllers/notification_controller.dart';
import 'Controllers/order_controller.dart';
import 'Controllers/password_controller.dart';
import 'Controllers/product_controller.dart';
import 'Controllers/review_controller.dart';
import 'Controllers/support_controller.dart';
import 'Controllers/wishlist_controller.dart';
import 'Screens/Admin/admin_coupons_screen.dart';
import 'Screens/Admin/admin_dashboard_screen.dart';
import 'Screens/Admin/admin_messages_screen.dart';
import 'Screens/Admin/admin_orders_screen.dart';
import 'Screens/Admin/admin_products_screen.dart';
import 'Screens/Admin/admin_users_screen.dart';
import 'Screens/Authentication/Views/splash_screen.dart';
import 'Screens/Authentication/forgot_password_screen.dart';
import 'Screens/Authentication/login_screen.dart';
import 'Screens/Authentication/signup_screen.dart';
import 'Screens/Checkout/address_screen.dart';
import 'Screens/Home/main_navigation_screen.dart';
import 'Screens/Notifications/notifications_screen.dart';
import 'Screens/Orders/orders_screen.dart';
import 'Screens/Profile/profile_screen.dart';
import 'Screens/Support/support_screen.dart';
import 'Screens/Wishlist/wishlist_screen.dart';
import 'Utils/app_theme.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => PasswordController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => ReviewController()),
        ChangeNotifierProvider(create: (_) => PaymentController()),
        ChangeNotifierProvider(create: (_) => WishlistController()),
        ChangeNotifierProvider(create: (_) => CouponController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => SupportController()),
      ],
      child: MaterialApp(
        title: 'BabyShopHub',
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => SignupScreen(),
          '/user-home': (_) => const MainNavigationScreen(),
          '/admin-dashboard': (_) => const AdminDashboardScreen(),
          '/admin-products': (_) => const AdminProductsScreen(),
          '/admin-orders': (_) => const AdminOrdersScreen(),
          '/admin-users': (_) => const AdminUsersScreen(),
          '/admin-coupons': (_) => const AdminCouponsScreen(),
          '/admin-messages': (_) => const AdminMessagesScreen(),
          '/checkout': (_) => const AddressScreen(),
          '/orders': (_) => const OrdersScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/support': (_) => const SupportScreen(),
          '/cart': (_) => const MainNavigationScreen(),
          '/forgot-password': (_) => const ForgotPasswordScreen(),
          '/wishlist': (_) => const WishlistScreen(),
          '/notifications': (_) => const NotificationsScreen(),
        },
      ),
    );
  }
}
