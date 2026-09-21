import 'package:flutter/material.dart';

/// Shared 104px Radar orb used on Home and on an active trip.
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
    this.pulse = 0,
    this.sweep = 0,
    this.touchKey = const ValueKey<String>('trip-radar-touch-target'),
  });

  final String title;
  final String status;
  final String subtitle;
  final VoidCallback? onTap;
  final bool active;
  final bool loading;
  final bool offer;
  final double pulse;
  final double sweep;
  final Key touchKey;

  @override
  Widget build(BuildContext context) {
    const mint = Color(0xFF58E5A6);
    const detectedGold = Color(0xFFFFD166);
    const detectedAmber = Color(0xFFFFA94D);
    final accent = offer
        ? Color.lerp(detectedGold, detectedAmber, pulse) ?? detectedGold
        : mint;
    final glowStrength = active ? 0.14 + (pulse * 0.30) : 0.08;
    final ringScale = active ? 0.74 + (pulse * 0.38) : 1.0;
    final secondWaveScale = active ? 0.84 + ((1 - pulse) * 0.24) : 1.0;

    return Semantics(
      button: true,
      label: "$title, $status. $subtitle",
      child: GestureDetector(
        key: touchKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: ringScale,
                child: Container(
                  width: 102,
                  height: 102,
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
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(offer ? 0.045 : 0.025),
                      border: Border.all(
                        color: accent.withOpacity(offer ? 0.42 : 0.20),
                        width: offer ? 1.35 : 1.0,
                      ),
                    ),
                  ),
                ),
              Container(
                width: 90,
                height: 90,
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
                width: 79,
                height: 79,
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
                    width: 75,
                    height: 75,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 2,
                        height: 18,
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
              Material(
                color: Colors.transparent,
                elevation: 16,
                shadowColor: const Color(0xFF12201C).withOpacity(0.38),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  width: 73,
                  height: 73,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
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
                      color: offer
                          ? accent.withOpacity(0.82)
                          : const Color(0xD9E7ECEE),
                      width: offer ? 1.9 : 1.6,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3D263238),
                        blurRadius: 11,
                        offset: Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Color(0x66FFFFFF),
                        blurRadius: 3,
                        offset: Offset(-1, -2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: null,
                    customBorder: const CircleBorder(),
                    splashColor: accent.withOpacity(0.14),
                    highlightColor: accent.withOpacity(0.07),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          child: Container(
                            width: offer ? 7 : 5,
                            height: offer ? 7 : 5,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.86),
                                  blurRadius: offer ? 11 : 7,
                                  spreadRadius: offer ? 2.5 : 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 16, 6, 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.8,
                                  height: 1.1,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2.5),
                              Text(
                                status,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: offer
                                      ? accent
                                      : const Color(0xFFE2E9E6),
                                  fontSize: 6.1,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                width: 10,
                                height: 1,
                                color: Colors.white.withOpacity(0.36),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFB7C2BE),
                                  fontSize: 5.9,
                                  height: 1.12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (loading)
                          Positioned(
                            bottom: 5,
                            child: SizedBox(
                              width: 8,
                              height: 8,
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
    );
  }
}
