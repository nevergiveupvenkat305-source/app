class LoanRow {
  final String id;
  final String shgId;
  final String memberId;
  final String memberName;
  final String purpose;
  final double amount;
  final double outstanding;
  final double emi;
  final int tenureMonths;
  final DateTime? disbursedOn;
  final String status;
  final DateTime? nextDueDate;

  const LoanRow({
    required this.id,
    required this.shgId,
    required this.memberId,
    required this.memberName,
    required this.purpose,
    required this.amount,
    required this.outstanding,
    required this.emi,
    required this.tenureMonths,
    this.disbursedOn,
    required this.status,
    this.nextDueDate,
  });

  factory LoanRow.fromRow(Map<String, dynamic> row) => LoanRow(
        id: row['id'] as String,
        shgId: row['shg_id'] as String,
        memberId: row['member_id'] as String,
        memberName: (row['profiles'] as Map<String, dynamic>?)?['name'] as String? ?? 'Member',
        purpose: row['purpose'] as String,
        amount: (row['amount'] as num).toDouble(),
        outstanding: (row['outstanding'] as num).toDouble(),
        emi: (row['emi'] as num).toDouble(),
        tenureMonths: row['tenure_months'] as int,
        disbursedOn: row['disbursed_on'] != null ? DateTime.parse(row['disbursed_on'] as String) : null,
        status: row['status'] as String,
        nextDueDate: row['next_due_date'] != null ? DateTime.parse(row['next_due_date'] as String) : null,
      );
}
