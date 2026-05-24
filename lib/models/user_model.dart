enum UserRole { employee, hrManager }

class UserModel {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String department;
  final String designation;
  final DateTime joinDate;
  final double salary;

  const UserModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.designation,
    required this.joinDate,
    required this.salary,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      return name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.toUpperCase();
    }
    return 'U';
  }

  String get roleLabel =>
      role == UserRole.hrManager ? 'HR Manager' : 'Employee';

  int get yearsOfService {
    final now = DateTime.now();
    return now.year - joinDate.year;
  }
}
