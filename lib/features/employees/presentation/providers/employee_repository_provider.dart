import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/features/employees/data/datasources/employee_local_datasource.dart';
import 'package:quickboom_hrm/features/employees/data/datasources/employee_remote_datasource.dart';
import 'package:quickboom_hrm/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:quickboom_hrm/features/employees/domain/repositories/employee_repository.dart';

/// Provider for local datasource.
final employeeLocalDatasourceProvider = Provider<EmployeeLocalDatasource>((ref) {
  return EmployeeLocalDatasource();
});

/// Provider for remote datasource.
final employeeRemoteDatasourceProvider = Provider<EmployeeRemoteDatasource>((ref) {
  return EmployeeRemoteDatasource();
});

/// Provider for EmployeeRepository instance.
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepositoryImpl(
    localDatasource: ref.watch(employeeLocalDatasourceProvider),
    remoteDatasource: ref.watch(employeeRemoteDatasourceProvider),
  );
});
