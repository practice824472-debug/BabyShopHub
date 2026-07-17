import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Controllers/admin_controller.dart';
import '../../Controllers/auth_controller.dart';
import '../../Models/admin_order_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AdminController>().loadAllAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF3B6FF6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirm(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<AdminController>(
        builder: (context, adminController, _) {
          final stats = adminController.dashboardStats;

          if (stats == null && adminController.error == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async => adminController.loadAllAdminData(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHero(context, adminController),
                if (adminController.error != null)
                  _buildErrorBanner(adminController.error!),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 720;
                          return GridView.count(
                            crossAxisCount: isWide ? 4 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: isWide ? 1.45 : 1.12,
                            children: [
                              _buildStatCard(
                                  'Users',
                                  '${stats?.totalUsers ?? 0}',
                                  Icons.people_alt,
                                  const Color(0xFF3B6FF6)),
                              _buildStatCard(
                                  'Orders',
                                  '${stats?.totalOrders ?? 0}',
                                  Icons.receipt_long,
                                  const Color(0xFF11A36A)),
                              _buildStatCard(
                                  'Products',
                                  '${stats?.totalProducts ?? 0}',
                                  Icons.inventory_2,
                                  const Color(0xFFF59E0B)),
                              _buildStatCard(
                                  'Revenue',
                                  '\$${(stats?.revenue ?? 0).toStringAsFixed(2)}',
                                  Icons.payments,
                                  const Color(0xFF8B5CF6)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Today at a glance',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniMetric(
                                'Pending',
                                '${stats?.pendingOrders ?? 0}',
                                Icons.pending_actions,
                                Colors.deepOrange,
                                onTap: () => Navigator.pushNamed(
                                    context, '/admin-orders')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniMetric(
                                'Active products',
                                '${stats?.activeProducts ?? 0}',
                                Icons.verified,
                                Colors.teal,
                                onTap: () => Navigator.pushNamed(
                                    context, '/admin-products')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Analytics',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      _buildWeeklySalesChart(context, adminController),
                      const SizedBox(height: 16),
                      _buildCategoryBreakdownChart(context, adminController),
                      const SizedBox(height: 16),
                      _buildTopProductsChart(context, adminController),
                      const SizedBox(height: 24),
                      Text(
                        'Management',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      _buildManagementTile(
                        context,
                        title: 'Manage Products',
                        subtitle: 'Add, edit, delete, and monitor inventory',
                        icon: Icons.shopping_bag_outlined,
                        color: const Color(0xFF3B6FF6),
                        onTap: () =>
                            Navigator.pushNamed(context, '/admin-products'),
                      ),
                      _buildManagementTile(
                        context,
                        title: 'Manage Orders',
                        subtitle: 'Track fulfillment, statuses, and shipping',
                        icon: Icons.local_shipping_outlined,
                        color: const Color(0xFF11A36A),
                        onTap: () =>
                            Navigator.pushNamed(context, '/admin-orders'),
                      ),
                      _buildManagementTile(
                        context,
                        title: 'Manage Users',
                        subtitle: 'Review customers and account access',
                        icon: Icons.admin_panel_settings_outlined,
                        color: const Color(0xFFF59E0B),
                        onTap: () =>
                            Navigator.pushNamed(context, '/admin-users'),
                      ),
                      _buildManagementTile(
                        context,
                        title: 'Manage Coupons',
                        subtitle: 'Create and track discount codes',
                        icon: Icons.local_offer_outlined,
                        color: const Color(0xFF8B5CF6),
                        onTap: () =>
                            Navigator.pushNamed(context, '/admin-coupons'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthController>().logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, AdminController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B6FF6), Color(0xFF6EA8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text(
                  'Your dashboard listens to live database updates.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: controller.loadAllAdminData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh admin data',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade100)),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(error, style: TextStyle(color: Colors.red.shade800)),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(.12),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(title,
              style: TextStyle(
                  color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(
      String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: Colors.grey.shade400),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chartCard(
      {required String title, required Widget child, double height = 180}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }

  Widget _buildWeeklySalesChart(
      BuildContext context, AdminController controller) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final totals = days.map((day) {
      return controller.orders
          .where((o) =>
              o.status != OrderStatus.cancelled &&
              o.createdAt.year == day.year &&
              o.createdAt.month == day.month &&
              o.createdAt.day == day.day)
          .fold<double>(0, (sum, o) => sum + o.totalPrice);
    }).toList();

    final maxVal = totals.fold<double>(0, (m, v) => v > m ? v : m);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return _chartCard(
      title: 'Sales — last 7 days',
      child: BarChart(
        BarChartData(
          maxY: maxVal <= 0 ? 10 : maxVal * 1.3,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  final day = days[index.clamp(0, days.length - 1)];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[day.weekday - 1],
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < totals.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: totals[i],
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xFF3B6FF6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownChart(
      BuildContext context, AdminController controller) {
    final Map<String, int> counts = {};
    for (final p in controller.products) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return _chartCard(
        title: 'Products by Category',
        child: const Center(child: Text('No product data yet')),
      );
    }

    // One distinct color per category. ProductCategories.values currently
    // has 8 entries — kept a couple of spares here so a color is never
    // reused (reusing one made two unrelated categories look identical in
    // the legend/chart, e.g. category #7 silently getting category #1's
    // color back).
    final colors = [
      const Color(0xFF3B6FF6),
      const Color(0xFF11A36A),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
      const Color(0xFF84CC16),
      const Color(0xFF6366F1),
      const Color(0xFFF97316),
    ];
    // Sort by count descending so the legend and pie slices are ordered
    // from most to least stocked category, instead of arbitrary map order.
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    return _chartCard(
      title: 'Products by Category',
      // Taller than the default 180: with up to 8 categories the legend
      // list needs more room than the bar/line charts on this dashboard,
      // otherwise its last rows get clipped against the card's bottom edge.
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: [
                  for (int i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: entries[i].value.toDouble(),
                      color: colors[i % colors.length],
                      title: '${(entries[i].value / total * 100).round()}%',
                      radius: 46,
                      titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(entries[i].key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Text('${entries[i].value}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsChart(
      BuildContext context, AdminController controller) {
    final Map<String, double> revenueByProduct = {};
    for (final order in controller.orders) {
      if (order.status == OrderStatus.cancelled) continue;
      for (final item in order.items) {
        revenueByProduct[item.productName] =
            (revenueByProduct[item.productName] ?? 0) + item.subtotal;
      }
    }

    final top = revenueByProduct.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topFive = top.take(5).toList();

    if (topFive.isEmpty) {
      return _chartCard(
        title: 'Top Products by Revenue',
        child: const Center(child: Text('No order data yet')),
      );
    }

    final maxVal = topFive.first.value;

    return _chartCard(
      title: 'Top Products by Revenue',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.3,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= topFive.length)
                    return const SizedBox.shrink();
                  final name = topFive[index].key;
                  final short =
                      name.length > 8 ? '${name.substring(0, 8)}…' : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(short,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < topFive.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: topFive[i].value,
                    width: 22,
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xFF11A36A),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(.12),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.shade500),
      ),
    );
  }
}
