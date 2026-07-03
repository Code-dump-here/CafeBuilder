import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PageNavigatorWrapper extends StatefulWidget {
  final Widget child;
  const PageNavigatorWrapper({super.key, required this.child});

  @override
  State<PageNavigatorWrapper> createState() => _PageNavigatorWrapperState();
}

class _PageNavigatorWrapperState extends State<PageNavigatorWrapper>
    with SingleTickerProviderStateMixin {
  double _x = 20;
  double _y = 380;
  bool _expanded = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  final List<Map<String, dynamic>> _pages = [
    {'label': 'Splash', 'route': '/splash', 'icon': Icons.coffee_outlined},
    {'label': 'Login', 'route': '/login', 'icon': Icons.login_rounded},
    {'label': 'Register', 'route': '/register', 'icon': Icons.person_add_outlined},
    {'label': 'Forgot', 'route': '/forgot', 'icon': Icons.lock_reset_outlined},
    {'label': 'OTP', 'route': '/sms-otp', 'icon': Icons.sms_outlined},
    {'label': 'New Pass', 'route': '/sms-change-password', 'icon': Icons.key_outlined},
    {'label': 'Success', 'route': '/success', 'icon': Icons.check_circle_outline},
    {'label': 'Roles', 'route': '/role-selection', 'icon': Icons.supervised_user_circle_outlined},
    {'label': 'New Project', 'route': '/project-onboarding', 'icon': Icons.add_business_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _navigate(BuildContext context, String route) {
    setState(() => _expanded = false);
    _animController.reverse();
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (_expanded)
            GestureDetector(
              onTap: _toggle,
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),
          Positioned(
            left: _x,
            top: _y,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_expanded)
                  ScaleTransition(
                    scale: _scaleAnim,
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: IntrinsicWidth(
                         child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: _pages.map((p) {
                            return InkWell(
                              onTap: () => _navigate(context, p['route'] as String),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 11),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(p['icon'] as IconData,
                                        color: AppColors.primary, size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      p['label'] as String,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        ),
                      ),
                    ),
                  ),
                // Bubble — handles both drag and tap
                GestureDetector(
                  onTap: _toggle,
                  onPanUpdate: (details) {
                    if (!_expanded) {
                      setState(() {
                        _x = (_x + details.delta.dx)
                            .clamp(0, MediaQuery.of(context).size.width - 56);
                        _y = (_y + details.delta.dy)
                            .clamp(0, MediaQuery.of(context).size.height - 56);
                      });
                    }
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB89B78), AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _expanded ? Icons.close_rounded : Icons.grid_view_rounded,
                        key: ValueKey(_expanded),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
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
