import 'package:movera/core/admin/driver_home_admin_content.dart';

/// Admin-controlled Home content. Local seed today, remote later.
abstract interface class DriverHomeConfigRepository {
  DriverHomeAdminConfig load();
}

class LocalDriverHomeConfigRepository implements DriverHomeConfigRepository {
  const LocalDriverHomeConfigRepository({
    this.service = const DriverHomeAdminContentService(),
  });

  final DriverHomeAdminContentService service;

  @override
  DriverHomeAdminConfig load() => service.load();
}
