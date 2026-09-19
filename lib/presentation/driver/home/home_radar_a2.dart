part of 'home.dart';

extension _DriverHomeRadarA2 on _DriverHomeState {
  Widget _buildHomeDirectOfferCardImpl(HomeDirectOffer offer) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColor.primary.withOpacity(0.34),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF11181C).withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEF1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    offer.category,
                    style: const TextStyle(
                      color: Color(0xFF252E3A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F6F0),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      offer.reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF257658),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _dismissHomeDirectOffer,
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFF7D898F),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  offer.fare,
                  style: const TextStyle(
                    color: Color(0xFF252E3A),
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.9,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFD7A02C),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  offer.rating,
                  style: const TextStyle(
                    color: Color(0xFF6F7B82),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              offer.detail,
              style: const TextStyle(
                color: Color(0xFF7D898F),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE4E8EA)),
            const SizedBox(height: 11),
            _homeDirectLocationRowImpl(
              color: AppColor.primary,
              title:
                  '${offer.pickupMinutes} min · ${offer.pickupKm.toStringAsFixed(1)} km away',
              subtitle: offer.pickup,
            ),
            const SizedBox(height: 9),
            _homeDirectLocationRowImpl(
              color: const Color(0xFF252E3A),
              title:
                  '${offer.tripMinutes} min · ${offer.tripKm.toStringAsFixed(1)} km trip',
              subtitle: offer.dropoff,
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _previewDirectOfferRoute(
                    offer.pickupPosition,
                    offer.dropoffPosition,
                  ),
                  icon: const Icon(Icons.alt_route_rounded, size: 17),
                  label: const Text('Route'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: _acceptHomeDirectOffer,
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF252E3A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _homeDirectLocationRowImpl({
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF252E3A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7D898F),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
