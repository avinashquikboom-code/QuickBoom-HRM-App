import 'dart:developer' as dev;
import 'package:quickboom_hrm/features/employees/data/datasources/employee_local_datasource.dart';
import 'package:quickboom_hrm/features/employees/data/datasources/employee_remote_datasource.dart';
import 'package:quickboom_hrm/features/employees/data/models/hopkid_employee_model.dart';
import 'package:quickboom_hrm/features/employees/domain/repositories/employee_repository.dart';

/// Implementation of [EmployeeRepository] that integrates local caching and remote sync.
class EmployeeRepositoryImpl implements EmployeeRepository {
  final EmployeeLocalDatasource localDatasource;
  final EmployeeRemoteDatasource remoteDatasource;

  EmployeeRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
  });

  @override
  Future<List<HopkidEmployeeModel>> fetchAndCache() async {
    try {
      final lastSync = await localDatasource.getLastSyncedAt();
      if (lastSync != null) {
        final age = DateTime.now().difference(lastSync);
        if (age.inMinutes < 5) {
          dev.log('ℹ️ [EmployeeRepository] Cache is fresh (age: ${age.inMinutes}m). Using cached data.', name: 'EmployeeRepository');
          final cached = await localDatasource.getCachedEmployees();
          if (cached.isNotEmpty) return cached;
        }
      }
      dev.log('🔄 [EmployeeRepository] Cache is stale or empty. Triggering remote sync...', name: 'EmployeeRepository');
      return await refresh();
    } catch (e) {
      dev.log('⚠️ [EmployeeRepository] Remote sync failed. Falling back to local cache: $e', name: 'EmployeeRepository');
      final cached = await localDatasource.getCachedEmployees();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<List<HopkidEmployeeModel>> refresh() async {
    final list = await remoteDatasource.getEmployees();
    await localDatasource.saveEmployees(list);
    return list;
  }

  @override
  Future<List<HopkidEmployeeModel>> getCachedEmployees() {
    return localDatasource.getCachedEmployees();
  }

  @override
  Future<DateTime?> getLastSyncedAt() {
    return localDatasource.getLastSyncedAt();
  }
}
