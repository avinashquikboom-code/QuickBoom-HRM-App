import 'package:quickboom_hrm/features/employees/data/models/hopkid_employee_model.dart';

/// Repository interface for managing HopKid employee master synchronization.
abstract class EmployeeRepository {
  /// Fetch the employee list (uses local cache if TTL < 24h).
  Future<List<HopkidEmployeeModel>> fetchAndCache();

  /// Forces a remote synchronization and updates local cache, bypassing the TTL.
  Future<List<HopkidEmployeeModel>> refresh();

  /// Retrieves the cached employee list without performing any remote checks.
  Future<List<HopkidEmployeeModel>> getCachedEmployees();

  /// Get the timestamp when the local database was last successfully updated.
  Future<DateTime?> getLastSyncedAt();
}
