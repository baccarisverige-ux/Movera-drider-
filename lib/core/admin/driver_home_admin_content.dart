class DriverHomeAdminConfig {
  const DriverHomeAdminConfig({
    required this.performance,
    required this.scheduledRides,
    required this.update,
    required this.eventsSectionTitle,
    required this.eventsSectionSubtitle,
    required this.events,
    required this.stockholmWork,
  });

  final DriverPerformanceConfig performance;
  final ScheduledRidesAdminConfig scheduledRides;
  final AppUpdateAdminConfig update;
  final String eventsSectionTitle;
  final String eventsSectionSubtitle;
  final List<DriverEventConfig> events;
  final StockholmWorkStatsConfig stockholmWork;
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
    required this.dateLabel,
    required this.timeLabel,
    required this.location,
    required this.description,
    required this.recommendedWindow,
    required this.demandLabel,
    required this.driverNote,
    required this.imageUrl,
    required this.imageCredit,
    required this.enabled,
  });

  final String id;
  final String title;
  final String category;
  final String dateLabel;
  final String timeLabel;
  final String location;
  final String description;
  final String recommendedWindow;
  final String demandLabel;
  final String driverNote;
  final String imageUrl;
  final String imageCredit;
  final bool enabled;
}

class StockholmAreaConfig {
  const StockholmAreaConfig({
    required this.name,
    required this.demandPercent,
    required this.demandLabel,
  });

  final String name;
  final int demandPercent;
  final String demandLabel;
}

class StockholmWorkStatsConfig {
  const StockholmWorkStatsConfig({
    required this.title,
    required this.subtitle,
    required this.innerAreas,
    required this.surroundingTitle,
    required this.surroundingSummary,
  });

  final String title;
  final String subtitle;
  final List<StockholmAreaConfig> innerAreas;
  final String surroundingTitle;
  final String surroundingSummary;
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
      eventsSectionTitle: 'What’s happening',
      eventsSectionSubtitle: 'Plan your shift around busy periods',
      events: [
        DriverEventConfig(
          id: 'stockholm-night-demand',
          title: 'Stockholm evening demand',
          category: 'Event',
          dateLabel: 'Fri 25 Sep',
          timeLabel: '18:00–22:30',
          location: 'Central Stockholm',
          description:
              'Expect concentrated pickup activity around the city centre and waterfront after evening events finish.',
          recommendedWindow: '18:30–22:00',
          demandLabel: 'Higher demand expected',
          driverNote:
              'Be online before the main departure window and stay close to legal pickup zones.',
          imageUrl:
              'https://images.unsplash.com/photo-1670257876831-7e97238da208?auto=format&fit=crop&q=82&w=1400',
          imageCredit: 'Håkon Grimstad · Unsplash',
          enabled: true,
        ),
        DriverEventConfig(
          id: 'stockholm-waterfront',
          title: 'Waterfront traffic window',
          category: 'Traffic',
          dateLabel: 'Sat 26 Sep',
          timeLabel: '16:30–20:00',
          location: 'Stockholm waterfront',
          description:
              'Large visitor movements can create temporary traffic pressure and higher ride demand around waterfront routes.',
          recommendedWindow: '17:00–19:30',
          demandLabel: 'Busy pickup window',
          driverNote:
              'Go online before the crowd leaves and use live routing to avoid blocked curb areas.',
          imageUrl:
              'https://images.unsplash.com/photo-1781040761543-fc71fcc17eb2?auto=format&fit=crop&q=82&w=1400',
          imageCredit: 'Rafael Peier · Unsplash',
          enabled: true,
        ),
        DriverEventConfig(
          id: 'stockholm-road-demand',
          title: 'Road demand alert',
          category: 'Demand',
          dateLabel: 'Sat 26 Sep',
          timeLabel: '22:00–02:00',
          location: 'Greater Stockholm',
          description:
              'Night-time road conditions and event departures can shift demand quickly between central and outer zones.',
          recommendedWindow: '22:30–01:30',
          demandLabel: 'Late-night demand',
          driverNote:
              'Stay online through the busiest window and check destination direction before matching longer trips.',
          imageUrl:
              'https://images.unsplash.com/photo-1511443259588-05878425294f?auto=format&fit=crop&q=82&w=1400',
          imageCredit: 'Federico Enni · Unsplash',
          enabled: true,
        ),
      ],
      stockholmWork: StockholmWorkStatsConfig(
        title: 'Work in Stockholm',
        subtitle: 'Inner city and the area around',
        innerAreas: [
          StockholmAreaConfig(
            name: 'Södermalm',
            demandPercent: 86,
            demandLabel: 'Busy',
          ),
          StockholmAreaConfig(
            name: 'Norrmalm',
            demandPercent: 78,
            demandLabel: 'Busy',
          ),
          StockholmAreaConfig(
            name: 'Östermalm',
            demandPercent: 64,
            demandLabel: 'Steady',
          ),
          StockholmAreaConfig(
            name: 'Kungsholmen',
            demandPercent: 57,
            demandLabel: 'Steady',
          ),
        ],
        surroundingTitle: 'Around Stockholm',
        surroundingSummary: 'Solna · Nacka · Huddinge · Täby',
      ),
    );
  }
}
