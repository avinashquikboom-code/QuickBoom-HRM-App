/// Typed model representing an Employee record from the HopKid external system.
class HopkidEmployeeModel {
  final String employeeID;
  final String employeeCode;
  final String employeeName;
  final String? gender;
  final String? dateofBirth;
  final String? dateofJoining;
  final int? pinCode;
  final String address;
  final String branchName;
  final String mobileNo;
  final String? email;
  final double salary;
  final double commissionPercentage;
  final String companyId;
  final String branchId;
  final bool isActive;
  final String createdBy;
  final String createdOn;
  final String updatedBy;
  final String updatedOn;
  final String branchId2;

  HopkidEmployeeModel({
    required this.employeeID,
    required this.employeeCode,
    required this.employeeName,
    this.gender,
    this.dateofBirth,
    this.dateofJoining,
    this.pinCode,
    required this.address,
    required this.branchName,
    required this.mobileNo,
    this.email,
    required this.salary,
    required this.commissionPercentage,
    required this.companyId,
    required this.branchId,
    required this.isActive,
    required this.createdBy,
    required this.createdOn,
    required this.updatedBy,
    required this.updatedOn,
    required this.branchId2,
  });

  factory HopkidEmployeeModel.fromJson(Map<String, dynamic> json) {
    return HopkidEmployeeModel(
      employeeID: json['employeeID'] ?? '',
      employeeCode: json['employeeCode'] ?? '',
      employeeName: json['employeeName'] ?? '',
      gender: json['gender'],
      dateofBirth: json['dateofBirth'],
      dateofJoining: json['dateofJoining'],
      pinCode: json['pinCode'] is int ? json['pinCode'] : null,
      address: json['address'] ?? '',
      branchName: json['branchName'] ?? '',
      mobileNo: json['mobileNo'] ?? '',
      email: json['email'],
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      commissionPercentage: (json['commissionPercentage'] as num?)?.toDouble() ?? 0.0,
      companyId: json['companyId'] ?? '',
      branchId: json['branchId'] ?? '',
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'] ?? '',
      createdOn: json['createdOn'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      updatedOn: json['updatedOn'] ?? '',
      branchId2: json['branchId2'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeID': employeeID,
      'employeeCode': employeeCode,
      'employeeName': employeeName,
      'gender': gender,
      'dateofBirth': dateofBirth,
      'dateofJoining': dateofJoining,
      'pinCode': pinCode,
      'address': address,
      'branchName': branchName,
      'mobileNo': mobileNo,
      'email': email,
      'salary': salary,
      'commissionPercentage': commissionPercentage,
      'companyId': companyId,
      'branchId': branchId,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdOn': createdOn,
      'updatedBy': updatedBy,
      'updatedOn': updatedOn,
      'branchId2': branchId2,
    };
  }
}
