class DriverHomeAdminConfig {
  const DriverHomeAdminConfig({
    required this.performance,
    required this.scheduledRides,
    required this.update,
    required this.events,
  });

  final DriverPerformanceConfig performance;
  final ScheduledRidesAdminConfig scheduledRides;
  final AppUpdateAdminConfig update;
  final List<DriverEventConfig> events;
}

class DriverPerformanceConfig {
  const DriverPerformanceConfig({
    required this.rating,
    required this.acceptanceRate,
    required this.cancellationRate,
    this.showRating = true,
    this.showAcceptanceRate = true,
    this.showCancellationRate = true,
  });

  final double rating;
  final double acceptanceRate;
  final double cancellationRate;
  final bool showRating;
  final bool showAcceptanceRate;
  final bool showCancellationRate;
}

class ScheduledRidesAdminConfig {
  const ScheduledRidesAdminConfig({
    required this.enabled,
    required this.hasOpenRequests,
    required this.title,
    required this.subtitle,
  });

  final bool enabled;
  final bool hasOpenRequests;
  final String title;
  final String subtitle;
}

class AppUpdateAdminConfig {
  const AppUpdateAdminConfig({
    required this.enabled,
    required this.latestVersion,
    required this.minimumVersion,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.dismissLabel,
    required this.mandatory,
    this.updateUrl,
  });

  final bool enabled;
  final String latestVersion;
  final String minimumVersion;
  final String title;
  final String message;
  final String actionLabel;
  final String dismissLabel;
  final bool mandatory;
  final String? updateUrl;
}

class DriverEventConfig {
  const DriverEventConfig({
    required this.id,
    required this.title,
    required this.category,
    required this.whenLabel,
    required this.location,
    required this.description,
    required this.driverNote,
    required this.imageUrl,
    required this.imageCredit,
    required this.enabled,
  });

  final String id;
  final String title;
  final String category;
  final String whenLabel;
  final String location;
  final String description;
  final String driverNote;
  final String imageUrl;
  final String imageCredit;
  final bool enabled;
}

/// Driver-side contract for content controlled by the Movera admin system.
///
/// Today this returns frontend seed data. When the backend/admin repository is
/// connected, only this service should change; Home UI consumes the same model.
class DriverHomeAdminContentService {
  const DriverHomeAdminContentService();

  DriverHomeAdminConfig load() {
    return const DriverHomeAdminConfig(
      performance: DriverPerformanceConfig(
        rating: 4.88,
        acceptanceRate: 94.0,
        cancellationRate: 2.4,
      ),
      scheduledRides: ScheduledRidesAdminConfig(
        enabled: true,
        hasOpenRequests: true,
        title: 'Scheduled rides available',
        subtitle: 'View open requests in your area',
      ),
      update: AppUpdateAdminConfig(
        enabled: false,
        latestVersion: '1.0.0',
        minimumVersion: '1.0.0',
        title: 'Movera Driver update available',
        message:
            'A newer version is ready with stability and trip-flow improvements.',
        actionLabel: 'Update app',
        dismissLabel: 'Later',
        mandatory: false,
      ),
      events: [
        DriverEventConfig(
          id: 'stockholm-night-demand',
          title: 'Stockholm evening demand',
          category: 'CITY EVENT',
          whenLabel: 'Evening',
          location: 'Central Stockholm',
          description:
              'Expect concentrated pickup activity around the city centre and waterfront after evening events finish.',
          driverNote:
              'Stay available near legal pickup zones and expect short bursts of demand.',
          imageUrl:
              'https://images.unsplash.com/photo-1670257876831-7e97238da208?auto=format&fit=crop&q=82&w=1400',
          imageCredit: 'Håkon Grimstad · Unsplash',
          enabled: true,
        ),
        DriverEventConfig(
          id: 'stockholm-waterfront',
          title: 'Waterfront traffic window',
          category: 'TRAFFIC',
          whenLabel: 'Peak window',
          location: 'Stockholm waterfront',
          description:
              'Large visitor movements can create temporary traffic pressure and higher ride demand around waterfront routes.',
          driverNote:
              'Use the live route before accepting your next pickup and avoid blocked curb areas.',
          imageUrl:
              'https://images.unsplash.com/photo-1781040761543-fc71fcc17eb2?auto=format&fit=crop&q=82&w=1400',
          imageCredit: 'Rafael Peier · Unsplash',
          enabled: true,
        ),
        DriverEventConfig(
          id: 'stockholm-road-demand',
          title: 'Road demand alert',
          category: 'DRIVER NOTE',
          whenLabel: 'Night',
          location: 'Greater Stockholm',
          description:
              'Night-time road conditions and event departures can shift demand quickly between central and outer zones.',
          driverNote:
              'Keep Radar active and check destination direction before matching longer trips.',
          imageUrl:
              'https://images.unsplash.com/photo-1511443259588-05878425294f?auto=format&fit=crop&q=82&w=1400',
          imageCredit: 'Federico Enni · Unsplash',
          enabled: true,
        ),
      ],
    );
  }
}
