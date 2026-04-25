// lib/features/home/presentation/home_screen.dart
// ─────────────────────────────────────────────
//  Home Screen
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/chargix_button.dart';
import '../../auth/data/services/booking_service.dart';
import '../../../main_shell.dart';
import '../../stations/station_service.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _stationService = StationService();

  List<ChargingStation> _stations = [];
  bool _loadingStations = true;

  late final AnimationController _greetingAnim;
  late final Animation<double> _greetingFade;
  late final Animation<Offset> _greetingSlide;

  // Demo user — replace with real auth state
  static final _demoUser = UserProfile(
    uid: 'demo',
    phoneNumber: '+962 7X XXX XXXX',
    displayName: 'EV Driver',
    points: 1240,
    vipLevel: VipLevel.silver,
    totalSessions: 28,
    totalKwhCharged: 312.5, createdAt: DateTime.now(),
   // createdAt: , 
  );

  @override
  void initState() {
    super.initState();
    _greetingAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _greetingFade = CurvedAnimation(
      parent: _greetingAnim,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _greetingSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _greetingAnim, curve: Curves.easeOutCubic));

    _greetingAnim.forward();
    _loadStations();
  }

  @override
  void dispose() {
    _greetingAnim.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    try {
      final list = await _stationService.getNearbyStations(
        lat: 31.9789, lng: 35.9187,
      );
      if (mounted) setState(() { _stations = list; _loadingStations = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStations = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ─────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.background,
            expandedHeight: 0,
            pinned: true,
            titleSpacing: AppSpacing.lg,
            title: FadeTransition(
              opacity: _greetingFade,
              child: SlideTransition(
                position: _greetingSlide,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _greeting,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          _demoUser.displayName ?? 'Driver',
                          style: AppTextStyles.headingMedium,
                        ),
                      ],
                    ),
                    const Spacer(),
                    PointsDisplay(points: _demoUser.points, compact: true),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // ── Pricing Card ───────────────────────────
                  _PricingCard(),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Active Session / Link Card ─────────────
                  _LinkSessionCard(),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Quick Actions ──────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.flash_on_rounded,
                          label: 'Quick Match',
                          subtitle: 'Nearest available',
                          color: AppColors.primary,
                          onTap: () => MainShell.switchTab(context, 1),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.map_rounded,
                          label: 'Open Map',
                          subtitle: 'Browse stations',
                          color: AppColors.accent,
                          onTap: () => MainShell.switchTab(context, 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── VIP Status Banner ──────────────────────
                  _VipBanner(profile: _demoUser),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Nearby Stations ────────────────────────
                  SectionHeader(
                    title: 'Nearby Stations',
                    action: 'View all',
                    onAction: () => MainShell.switchTab(context, 1),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_loadingStations)
                    Column(children: List.generate(3, (_) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ShimmerBox(
                          width: double.infinity, height: 90, borderRadius: 16),
                    )))
                  else if (_stations.isEmpty)
                    EmptyState(
                      icon: Icons.ev_station_rounded,
                      title: 'No stations found',
                      subtitle: 'Stations will appear as data loads',
                    )
                  else
                    ..._stations.take(3).map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: StationCard(
                        station: s,
                        onTap: () => _openStation(s),
                      ),
                    )),

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openStation(ChargingStation station) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StationDetailScreen(station: station),
    ));
  }
}

// ─────────────────────────────────────────────
//  Dynamic Pricing Card
// ─────────────────────────────────────────────
class _PricingCard extends StatelessWidget {
  _PricingCard();

  PricingTier get _currentTier =>
      PricingConfig.tierForTime(DateTime.now());

  double get _currentRate =>
      PricingConfig.baseRateJod * _currentTier.multiplier;

  @override
  Widget build(BuildContext context) {
    final tier = _currentTier;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Rate',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) =>
                          AppColors.primaryGradient.createShader(
                        Rect.fromLTWH(0, 0, b.width, b.height),
                      ),
                      child: Text(
                        _currentRate.toStringAsFixed(3),
                        style: AppTextStyles.displayMedium.copyWith(
                          fontSize: 34,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'JD/kWh',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PricingBadge(tier: tier),
              ],
            ),
          ),
          // Dial graphic
          _PriceDial(tier: tier),
        ],
      ),
    );
  }
}

class _PriceDial extends StatelessWidget {
  final PricingTier tier;
  const _PriceDial({required this.tier});

  @override
  Widget build(BuildContext context) {
    final progress = switch (tier) {
      PricingTier.superOffPeak => 0.25,
      PricingTier.offPeak => 0.55,
      PricingTier.peak => 0.85,
    };
    final color = switch (tier) {
      PricingTier.superOffPeak => AppColors.accent,
      PricingTier.offPeak => AppColors.primary,
      PricingTier.peak => AppColors.error,
    };

    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _DialPainter(progress: progress, color: color),
        child: Center(
          child: Text(
            '${(progress * 100).toInt()}%',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  final Color color;
  _DialPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

    const start = -2.356; // -135 deg
    const sweep = 4.712;  // 270 deg

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start, sweep, false, trackPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start, sweep * progress, false, progressPaint,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────
//  Link Session Card
// ─────────────────────────────────────────────
class _LinkSessionCard extends StatelessWidget {
  const _LinkSessionCard();

  @override
  Widget build(BuildContext context) {
    // Replace with real active session check
    const hasActive = false;

    if (hasActive) {
      return _ActiveSessionBanner();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.link_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Link Charging Session',
                    style: AppTextStyles.labelLarge),
                Text('Scan QR code at the charger',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text('Scan',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.accent.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Charging Active', style: AppTextStyles.labelLarge),
                Text('Abdali Hub  ·  32 min remaining',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Text('42%', style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.primary,
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Quick Action Tile
// ─────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(label, style: AppTextStyles.labelLarge),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  VIP Status Banner
// ─────────────────────────────────────────────
class _VipBanner extends StatelessWidget {
  final UserProfile profile;
  const _VipBanner({required this.profile});

  int get _nextThreshold {
    final level = profile.vipLevel;
    return switch (level) {
      VipLevel.normal => VipLevel.silver.pointsRequired,
      VipLevel.silver => VipLevel.gold.pointsRequired,
      VipLevel.gold   => VipLevel.gold.pointsRequired,
    };
  }

  @override
  Widget build(BuildContext context) {
    final progress = (profile.points / _nextThreshold).clamp(0.0, 1.0);
    final isGold = profile.vipLevel == VipLevel.gold;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isGold
              ? [const Color(0xFF2A2010), const Color(0xFF1A1508)]
              : [AppColors.surfaceElevated, AppColors.surface],
        ),
        border: Border.all(
          color: isGold
              ? const Color(0xFFFFD700).withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VipBadge(level: profile.vipLevel),
              const Spacer(),
              Text(
                '${profile.points} pts',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isGold ? const Color(0xFFFFD700) : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isGold ? const Color(0xFFFFD700) : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (!isGold)
            Text(
              '${_nextThreshold - profile.points} pts to ${VipLevel.values[profile.vipLevel.index + 1].label}',
              style: AppTextStyles.caption,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Station Detail Screen (mini, opens from home/map)
// ─────────────────────────────────────────────
class StationDetailScreen extends StatelessWidget {
  final ChargingStation station;
  const StationDetailScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.textPrimary),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.surface,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.ev_station_rounded,
                        size: 64, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(station.name,
                                style: AppTextStyles.headingLarge),
                            const SizedBox(height: 4),
                            Text(station.address,
                                style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFD700), size: 15),
                            const SizedBox(width: 3),
                            Text(station.rating.toStringAsFixed(1),
                                style: AppTextStyles.labelLarge),
                          ]),
                          Text('${station.reviewCount} reviews',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Stats row
                  Row(
                    children: [
                      StatTile(
                        label: 'Base Rate',
                        value: station.baseRatePerKwh.toStringAsFixed(2),
                        unit: 'JD/kWh',
                        icon: Icons.monetization_on_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatTile(
                        label: 'Available',
                        value: '${station.availableCount}',
                        unit: '/ ${station.chargers.length}',
                        icon: Icons.electrical_services_rounded,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Chargers list
                  Text('Chargers', style: AppTextStyles.headingMedium),
                  const SizedBox(height: AppSpacing.md),
                  ...station.chargers.map((c) => _ChargerRow(charger: c,
                    onBook: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(
                          station: station, charger: c,
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: AppSpacing.xl),
                  if (station.amenities.isNotEmpty) ...[
                    Text('Amenities', style: AppTextStyles.headingMedium),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      children: station.amenities.map((a) => Chip(
                        label: Text(a),
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: AppTextStyles.caption,
                        side: const BorderSide(color: AppColors.border),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargerRow extends StatelessWidget {
  final Charger charger;
  final VoidCallback onBook;
  const _ChargerRow({required this.charger, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(charger.type.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(charger.type.label, style: AppTextStyles.labelLarge),
                Text('${charger.powerKw.toInt()} kW',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          StatusBadge(status: charger.status),
          const SizedBox(width: AppSpacing.sm),
          if (charger.status == ChargerStatus.available)
            GestureDetector(
              onTap: onBook,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text('Book',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
        ],
      ),
    );
  }
}

// Forward declaration – implemented in booking_screen.dart
class BookingScreen extends StatefulWidget {
  final ChargingStation station;
  final Charger charger;
  const BookingScreen({super.key, required this.station, required this.charger});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}