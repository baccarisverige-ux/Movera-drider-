import 'package:flutter/material.dart';

/// Shared Radar orb used on Home (104px) and on an active trip (smaller).
class MoveraRadarOrb extends StatelessWidget {
  const MoveraRadarOrb({
    super.key,
    required this.title,
    required this.status,
    required this.subtitle,
    this.onTap,
    this.active = false,
    this.loading = false,
    this.offer = false,
    this.exclusive = false,
    this.pulse = 0,
    this.sweep = 0,
    this.size = 104,
    this.touchSize,
    this.touchKey = const ValueKey<String>('trip-radar-touch-target'),
  });

  final String title;
  final String status;
  final String subtitle;
  final VoidCallback? onTap;
  final bool active;
  final bool loading;
  final bool offer;
  final bool exclusive;
  final double pulse;
  final double sweep;
  final double size;
  final double? touchSize;
  final Key touchKey;

  @override
  Widget build(BuildContext context) {
    const mint = Color(0xFF58E5A6);
    const detectedGold = Color(0xFFFFD166);
    const detectedAmber = Color(0xFFFFA94D);
    const exclusiveBlue = Color(0xFF4E8DFF);
    const exclusiveViolet = Color(0xFF8A6CFF);
    final accent = exclusive
        ? (Color.lerp(exclusiveBlue, exclusiveViolet, pulse) ?? exclusiveBlue)
        : offer
            ? (Color.lerp(detectedGold, detectedAmber, pulse) ?? detectedGold)
            : mint;
    final glowStrength = !active
        ? 0.08
        : loading
            ? 0.10 + (pulse * 0.14)
            : exclusive
                ? 0.20 + (pulse * 0.34)
                : offer
                    ? 0.14 + (pulse * 0.26)
                    : 0.11 + (pulse * 0.16);
    final ringScale = !active
        ? 1.0
        : loading
            ? 0.96 + (pulse * 0.07)
            : exclusive
                ? 0.80 + (pulse * 0.28)
                : offer
                    ? 0.84 + (pulse * 0.22)
                    : 0.91 + (pulse * 0.12);
    final secondWaveScale = !active
        ? 1.0
        : loading
            ? 0.90 + ((1 - pulse) * 0.10)
            : exclusive
                ? 0.80 + ((1 - pulse) * 0.22)
                : 0.86 + ((1 - pulse) * 0.16);
    final s = size / 104;
    final hit = touchSize ?? size;

    return Semantics(
      button: true,
      label: "$title, $status. $subtitle",
      child: GestureDetector(
        key: touchKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: hit,
          height: hit,
          child: Center(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: ringScale,
                    child: Container(
                      width: 102 * s,
                      height: 102 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(active ? 0.04 : 0.025),
                        border: Border.all(
                          color: accent.withOpacity(active ? 0.30 : 0.15),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  if (active)
                    Transform.scale(
                      scale: secondWaveScale,
                      child: Container(
                        width: 96 * s,
                        height: 96 * s,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(
                            exclusive ? 0.07 : offer ? 0.045 : 0.025,
                          ),
                          border: Border.all(
                            color: accent.withOpacity(
                              exclusive ? 0.60 : offer ? 0.42 : 0.20,
                            ),
                            width: exclusive ? 1.55 : offer ? 1.35 : 1.0,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 90 * s,
                    height: 90 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(active ? 0.045 : 0.03),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.72),
                        width: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    width: 79 * s,
                    height: 79 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFBFD9CF).withOpacity(0.12),
                      border: Border.all(
                        color: accent.withOpacity(active ? 0.38 : 0.19),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(glowStrength),
                          blurRadius: active ? 19 : 11,
                          spreadRadius: active ? 5 : 2,
                        ),
                      ],
                    ),
                  ),
                  if (active)
                    Transform.rotate(
                      angle: sweep * 6.283185307179586,
                      child: SizedBox(
                        width: 75 * s,
                        height: 75 * s,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 2,
                            height: 18 * s,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  accent.withOpacity(0),
                                  accent.withOpacity(offer ? 0.95 : 0.78),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (active && exclusive)
                    Transform.rotate(
                      angle: (1 - sweep) * 6.283185307179586,
                      child: SizedBox(
                        width: 86 * s,
                        height: 86 * s,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 2.2,
                            height: 22 * s,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  accent.withOpacity(0),
                                  accent.withOpacity(0.88),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Material(
                    color: Colors.transparent,
                    elevation: 16,
                    shadowColor: const Color(0xFF12201C).withOpacity(0.38),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: Ink(
                      width: 73 * s,
                      height: 73 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: exclusive
                            ? const RadialGradient(
                                center: Alignment(-0.24, -0.32),
                                radius: 0.98,
                                colors: [
                                  Color(0xE06F7EA6),
                                  Color(0xE04D5F89),
                                  Color(0xED303B59),
                                ],
                                stops: [0, 0.58, 1],
                              )
                            : const RadialGradient(
                                center: Alignment(-0.24, -0.32),
                                radius: 0.98,
                                colors: [
                                  Color(0xD98F999C),
                                  Color(0xD9727D80),
                                  Color(0xE05A6468),
                                ],
                                stops: [0, 0.58, 1],
                              ),
                        border: Border.all(
                          color: exclusive
                              ? accent.withOpacity(0.95)
                              : offer
                                  ? accent.withOpacity(0.82)
                                  : const Color(0xD9E7ECEE),
                          width: exclusive ? 2.1 : offer ? 1.9 : 1.6,
                        ),
                      ),
                      child: InkWell(
                        onTap: null,
                        customBorder: const CircleBorder(),
                        splashColor: accent.withOpacity(0.14),
                        highlightColor: accent.withOpacity(0.07),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(6 * s, 16 * s, 6 * s, 4 * s),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.8 * s,
                                      height: 1.1,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2.5 * s),
                                  Text(
                                    status,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: offer
                                          ? accent
                                          : const Color(0xFFE2E9E6),
                                      fontSize: 6.1 * s,
                                      height: 1,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                  SizedBox(height: 3 * s),
                                  Container(
                                    width: 10 * s,
                                    height: 1,
                                    color: Colors.white.withOpacity(0.36),
                                  ),
                                  SizedBox(height: 4 * s),
                                  Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFFB7C2BE),
                                      fontSize: 5.9 * s,
                                      height: 1.12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (loading)
                              Positioned(
                                bottom: 5 * s,
                                child: SizedBox(
                                  width: 8 * s,
                                  height: 8 * s,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.1,
                                    color: accent.withOpacity(0.90),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
