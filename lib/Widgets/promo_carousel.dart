import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

/// A single auto-scrolling promotional banner.
class PromoBanner {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const PromoBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
}

/// Auto-scrolling, swipeable, infinitely-looping promo carousel shown above
/// the search bar on the home screen. Banners are drawn (gradient + icon)
/// rather than loaded from Firebase Storage, since the app has no
/// promotional image assets yet — swap in `Image.network` inside the
/// banner card once real campaign artwork exists.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  static const List<PromoBanner> _banners = [
    PromoBanner(
      title: 'New Arrivals',
      subtitle: 'Fresh baby essentials, just landed',
      icon: Icons.auto_awesome,
      colors: [Color(0xFF3B6FF6), Color(0xFF6EA8FF)],
    ),
    PromoBanner(
      title: 'Summer Sale',
      subtitle: 'Up to 30% off select items',
      icon: Icons.wb_sunny,
      colors: [Color(0xFFF59E0B), Color(0xFFFFC069)],
    ),
    PromoBanner(
      title: 'Baby Essentials',
      subtitle: 'Everything for daily care, in one place',
      icon: Icons.child_care,
      colors: [Color(0xFF11A36A), Color(0xFF5FD897)],
    ),
    PromoBanner(
      title: 'Free Delivery',
      subtitle: 'On all orders over \$40',
      icon: Icons.local_shipping,
      colors: [Color(0xFF8B5CF6), Color(0xFFB79CFF)],
    ),
    PromoBanner(
      title: '50% Off Selected Items',
      subtitle: 'Limited time — grab them before they\'re gone',
      icon: Icons.local_offer,
      colors: [Color(0xFFEF4444), Color(0xFFFF8A8A)],
    ),
  ];

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 130,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 600),
            enlargeCenterPage: false,
            enableInfiniteScroll: true,
            onPageChanged: (index, reason) {
              setState(() => _activeIndex = index);
            },
          ),
          items: PromoCarousel._banners.map((banner) {
            return _PromoCard(banner: banner);
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(PromoCarousel._banners.length, (index) {
            final isActive = index == _activeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? PromoCarousel._banners[_activeIndex].colors.first
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromoBanner banner;

  const _PromoCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: banner.colors,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  banner.subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(banner.icon, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}
