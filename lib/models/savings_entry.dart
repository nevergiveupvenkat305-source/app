class SavingsEntryRow {
  final String id;
  final String shgId;
  final String memberId;
  final String memberName;
  final DateTime entryDate;
  final double amount;
  final String mode;
  final String frequency;
  final String status;

  const SavingsEntryRow({
    required this.id,
    required this.shgId,
    required this.memberId,
    required this.memberName,
    required this.entryDate,
    required this.amount,
    required this.mode,
    required this.frequency,
    required this.status,
  });

  factory SavingsEntryRow.fromRow(Map<String, dynamic> row) => SavingsEntryRow(
        id: row['id'] as String,
        shgId: row['shg_id'] as String,
        memberId: row['member_id'] as String,
        memberName: (row['profiles'] as Map<String, dynamic>?)?['name'] as String? ?? 'Member',
        entryDate: DateTime.parse(row['entry_date'] as String),
        amount: (row['amount'] as num).toDouble(),
        mode: row['mode'] as String,
        frequency: row['frequency'] as String,
        status: row['status'] as String,
      );
}
