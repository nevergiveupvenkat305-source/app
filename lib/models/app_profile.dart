class AppProfile {
  final String id;
  final String name;
  final String? mobile;
  final String role;
  final String? shgId;
  final String? village;

  const AppProfile({
    required this.id,
    required this.name,
    this.mobile,
    required this.role,
    this.shgId,
    this.village,
  });

  factory AppProfile.fromRow(Map<String, dynamic> row) => AppProfile(
        id: row['id'] as String,
        name: row['name'] as String,
        mobile: row['mobile'] as String?,
        role: row['role'] as String,
        shgId: row['shg_id'] as String?,
        village: row['village'] as String?,
      );
}
