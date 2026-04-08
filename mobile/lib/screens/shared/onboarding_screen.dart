import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 2 state – category selection
  final Set<String> _selectedCategories = {};

  // Page 3 state – age range selection
  String? _selectedAge;

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/auth/login');
    }
  }

  void _skip() => context.go('/auth/login');

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Gradient top decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: _buildPageBackground(_currentPage),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (hidden on first page)
                      AnimatedOpacity(
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          onPressed: _currentPage > 0
                              ? () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOutCubic,
                                  )
                              : null,
                          icon: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),

                      // Skip button
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.85),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _WelcomePage(),
                      _CategoriesPage(
                        selected: _selectedCategories,
                        onToggle: (cat) => setState(() {
                          if (_selectedCategories.contains(cat)) {
                            _selectedCategories.remove(cat);
                          } else {
                            _selectedCategories.add(cat);
                          }
                        }),
                      ),
                      _AgePage(
                        selected: _selectedAge,
                        onSelect: (age) => setState(() => _selectedAge = age),
                      ),
                      _LocationPage(),
                      _NotificationsPage(),
                    ],
                  ),
                ),

                // Page indicators + CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                  child: Column(
                    children: [
                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: AppTheme.floatingShadow,
                          ),
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              _currentPage == 4 ? 'Get Started' : 'Continue',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_currentPage == 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton(
                            onPressed: () => context.go('/auth/login'),
                            child: Text(
                              'Already have an account? Sign In',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBackground(int page) {
    final colors = [
      [AppTheme.primaryColor, AppTheme.primaryLight],
      [const Color(0xFFFF6B35), const Color(0xFFFF8E53)],
      [const Color(0xFF7C3AED), const Color(0xFF9B70F5)],
      [const Color(0xFF059669), const Color(0xFF34D399)],
      [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
    ];

    final c = colors[page];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c[0], c[1]],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
      ),
    );
  }
}

// ─── Page 1: Welcome ──────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.local_offer_rounded, size: 50, color: AppTheme.primaryColor),
            ),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          Text(
            'Welcome to\nPromofy',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0, delay: 200.ms, duration: 500.ms, curve: Curves.easeOut),

          const SizedBox(height: 12),

          Text(
            'Discover exclusive deals from local\nrestaurants, bars & cafes near you.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 350.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0, delay: 350.ms, duration: 500.ms),

          const SizedBox(height: 40),

          // Feature pills
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _FeaturePill(Icons.location_on_rounded, 'Near You'),
              _FeaturePill(Icons.bolt_rounded, 'Real-time'),
              _FeaturePill(Icons.qr_code_rounded, 'Easy Redeem'),
            ],
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2: Category Selection ───────────────────────────────────────────────
class _CategoriesPage extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _CategoriesPage({required this.selected, required this.onToggle});

  static const _categories = [
    ('Restaurant', Icons.restaurant_rounded, Color(0xFFFF6B35)),
    ('Bar', Icons.local_bar_rounded, Color(0xFF7C3AED)),
    ('Cafe', Icons.coffee_rounded, Color(0xFF92400E)),
    ('Food Truck', Icons.delivery_dining_rounded, Color(0xFF059669)),
    ('Bakery', Icons.cake_rounded, Color(0xFFDB2777)),
    ('Pizza', Icons.local_pizza_rounded, Color(0xFFDC2626)),
    ('Sushi', Icons.set_meal_rounded, Color(0xFF0284C7)),
    ('Fast Food', Icons.fastfood_rounded, Color(0xFFD97706)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'What are you\ninterested in?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 6),
          Text(
            'Select all that apply',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white.withOpacity(0.75),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 48),

          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, i) {
              final (label, icon, color) = _categories[i];
              final isSelected = selected.contains(label);
              return GestureDetector(
                onTap: () => onToggle(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? color.withOpacity(0.25)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon,
                            size: 24,
                            color: isSelected ? Colors.white : color),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 50 * i), duration: 300.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      delay: Duration(milliseconds: 50 * i),
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Page 3: Age Range ────────────────────────────────────────────────────────
class _AgePage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _AgePage({required this.selected, required this.onSelect});

  static const _ages = ['18 – 24', '25 – 34', '35 – 44', '45+'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'How old\nare you?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0, duration: 400.ms),
          const SizedBox(height: 6),
          Text(
            'Help us personalise your deals',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white.withOpacity(0.75),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 52),

          ...List.generate(_ages.length, (i) {
            final age = _ages[i];
            final isSelected = selected == age;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => onSelect(age),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? AppTheme.floatingShadow
                        : AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      Text(
                        age,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white.withOpacity(0.25)
                              : AppTheme.inputFill,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.dividerColor,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 80 * i), duration: 350.ms)
                  .slideX(
                    begin: 0.3,
                    end: 0,
                    delay: Duration(milliseconds: 80 * i),
                    duration: 350.ms,
                    curve: Curves.easeOut,
                  ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Page 4: Location ─────────────────────────────────────────────────────────
class _LocationPage extends StatelessWidget {
  Future<void> _requestLocation() async {
    await Permission.location.request();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.location_on_rounded, size: 60, color: Color(0xFF059669)),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 28),

          const Text(
            'Enable your\nlocation',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 12),

          Text(
            'Promofy uses your location to show\nexclusive deals in real time, near you.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white.withOpacity(0.82),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

          const SizedBox(height: 40),

          // Enable button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _requestLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF059669),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.my_location_rounded),
              label: const Text(
                'Enable Location',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ─── Page 5: Notifications ────────────────────────────────────────────────────
class _NotificationsPage extends StatelessWidget {
  Future<void> _requestNotifications() async {
    await Permission.notification.request();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),

          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.notifications_active_rounded,
                size: 60, color: Color(0xFF0284C7)),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 28),

          const Text(
            'Turn on\nNotifications',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 12),

          Text(
            'Get notified when you\'re near a hot deal.\nNo spam — just deals you\'ll love.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white.withOpacity(0.82),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _requestNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0284C7),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.notifications_rounded),
              label: const Text(
                'Enable Notifications',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
