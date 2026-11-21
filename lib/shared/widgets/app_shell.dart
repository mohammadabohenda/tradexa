import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final String label;
  final String route;
  const NavItem({required this.icon, required this.label, required this.route});
}

/// الهيكل الثابت لكل شاشات تطبيق Admin: Sidebar داكن على اليمين
/// (لأن الاتجاه RTL) + منطقة محتوى فاتحة. هذا يعطي هوية بصرية
/// متسقة عبر كل الشاشات بدل ما كل شاشة تبني Scaffold خاص فيها.
class AppShell extends StatelessWidget {
  final String currentRoute;
  final Widget child;
  final String pageTitle;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.currentRoute,
    required this.child,
    required this.pageTitle,
    this.actions,
  });

  static const _items = [
    NavItem(icon: Icons.insights_outlined, label: 'الأرباح', route: '/stats'),
    NavItem(icon: Icons.dashboard_outlined, label: 'القطاعات', route: '/verticals'),
    NavItem(icon: Icons.sell_outlined, label: 'الأصناف', route: '/categories'),
    NavItem(icon: Icons.shopping_bag_outlined, label: 'المنتجات', route: '/products'),
    NavItem(icon: Icons.receipt_long_outlined, label: 'الطلبات', route: '/orders'),
    NavItem(icon: Icons.people_outline, label: 'المستخدمون', route: '/users'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(items: _items, currentRoute: currentRoute),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(title: pageTitle, actions: actions),
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<NavItem> items;
  final String currentRoute;

  const _Sidebar({required this.items, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.accentDark,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.sm,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/tradexa_logo.jpg',
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            ...items.map((item) => _SidebarTile(
                  item: item,
                  selected: currentRoute == item.route,
                )),
            const Spacer(),
            const _SidebarFooter(),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final NavItem item;
  final bool selected;

  const _SidebarTile({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
        borderRadius: AppRadius.sm,
        child: InkWell(
          borderRadius: AppRadius.sm,
          onTap: () {
            if (!selected) {
              Navigator.of(context).pushReplacementNamed(item.route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? AppColors.primary : Colors.white70,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: AppRadius.sm,
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Platform Admin',
                style: TextStyle(color: Colors.white, fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const _Header({required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
