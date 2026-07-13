# BabyShopHub — Flutter E-Commerce App

A university-level final project: a full-featured baby products e-commerce app built with Flutter + Firebase.

## Stack

- **Frontend**: Flutter (Dart), Material 3
- **Backend**: Firebase (Auth, Firestore, Storage)
- **State Management**: Provider
- **Architecture**: MVC (Models / Controllers / Screens)

## Running the App

This is a Flutter mobile app targeting Android and iOS. It **cannot be run directly on Replit** (no emulator available). Development is done in Android Studio or VS Code with a connected device/emulator.

To get started locally:
```bash
flutter pub get
flutter run
```

## Firebase Setup

Firebase is already configured (`firebase_options.dart`, `google-services.json`). The project uses:
- `users` — user profiles and roles (user/admin)
- `products` — product catalog
- `carts` — per-user cart (keyed by uid)
- `orders` — placed orders (full snapshots)
- `reviews` — product reviews (Phase 4)

## Project Structure

```
lib/
├── Models/           # Data models (product, cart, order, admin)
├── Controllers/      # Provider controllers (auth, product, cart, order, admin, password)
├── Screens/
│   ├── Authentication/   # Splash, Login, Signup
│   ├── Home/             # MainNavigationScreen, UserHomeScreen
│   ├── Products/         # ProductDetailsScreen
│   ├── Cart/             # CartScreen
│   ├── Checkout/         # AddressScreen → PaymentScreen → OrderConfirmationScreen
│   └── Admin/            # Dashboard, Products, Orders, Users
├── Utils/            # AppTheme, AppNavigator
└── main.dart
```

## Build Progress

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | Firebase Auth, Splash, Role-based routing | ✅ Done |
| 2 | Home, Product grid, Search, Product Details | ✅ Done |
| 3 | Cart | ✅ Done |
| 3 | Checkout (Address → Payment → Confirmation) | ✅ Done |
| 4 | Orders screen, Order tracking | ✅ Done |
| 4 | Reviews & Ratings | 🔜 Next |
| 5 | Admin Panel | ✅ Done |
| — | Profile screen (edit, password, addresses, logout) | ✅ Done |
| — | Support / FAQ | 🔜 Next |

## Known Issues / TODOs

- Duplicate HomeScreen files (`home_screen.dart` vs `Home_Screen.dart`) — cleanup needed
- SignupScreen instantiates a local `AuthController` instead of reading from Provider
- Orders and Profile tabs in bottom nav are still placeholder screens
- Search is client-side only (no Firestore query)
- Google Sign-In only works out of the box on Android/iOS. Running on Flutter Web (e.g. `flutter run -d chrome`) will throw `ClientID not set` when Google Sign-In is used, because it needs its own OAuth Web client ID — see the comment in `web/index.html` for how to add it.
- `flutter analyze` is clean of warnings/errors; the remaining ~80 issues are all `info`-level style suggestions (deprecated `withOpacity`/`value` usages, `prefer_const_constructors`, `use_build_context_synchronously`) — safe to leave, tackle incrementally if desired.

## Saved Addresses

Saved delivery addresses are stored as structured data (`lib/Models/address_model.dart`: `street`/`city`/`postalCode`), not a single joined string. The previous "Street, City, PostalCode" string format broke whenever a street address itself contained a comma, and silently dropped city/postal code when the format didn't line up — re-parsing a flattened string on every read was inherently fragile. `AuthController.addresses` is `List<AddressModel>`; `AddressModel.fromDynamic` still reads old string-formatted entries already in Firestore so existing saved addresses keep working. The "Add Address" dialog (`saved_addresses_screen.dart`) now picks the city from the same `pakistanCities` list the checkout screen uses, so a saved address's city always matches an entry in the checkout city dropdown.

## Image Uploads (Cloudinary)

Admin product images are uploaded directly to Cloudinary from the app (unsigned upload, no API secret bundled client-side):

- `lib/Services/cloudinary_service.dart` — posts multipart image data to `https://api.cloudinary.com/v1_1/<cloud_name>/image/upload`
- Cloud name and unsigned upload preset are set as constants in that file (`t7bqibfu` / `babyshophub`) — update them there if the Cloudinary account changes
- Used in `lib/Screens/Admin/admin_products_screen.dart` — admins pick a photo from the gallery, it uploads on Save, and the returned `secure_url` is stored as the product's `image` field in Firestore (the old free-text "Image URL" field is gone)

## Product Categories

`lib/Utils/product_categories.dart` is the single source of truth for category names (`Diapers`, `Baby Food`, `Toys`, `Clothes`, `Baby Care`, `Feeding`, `Bath`, `Accessories`). Both the admin add/edit product dropdown and the customer-facing category filter (`ProductController.categories`) read from this list, so a product's category can no longer be mistyped or drift out of sync between admin entry and customer filtering.

## Branded Transitions

`SplashScreen` (`lib/Screens/Authentication/Views/splash_screen.dart`) now accepts `loadingMessage` and `duration` parameters and is reused (not just shown on cold start):
- After a successful login (email or Google, either role) — "Logging in..."
- After logout from the Profile screen — "Logging out..."

Its existing role-based routing logic (checks `auth.user` / `auth.isAdmin`) handles sending the user to `/login`, `/user-home`, or `/admin-dashboard` correctly in both cases.

## User Preferences

- Keep existing project structure and naming conventions (MVC, PascalCase files)
- Use Provider for all state management
- Firebase Firestore for all persistence
- Material 3 design throughout
