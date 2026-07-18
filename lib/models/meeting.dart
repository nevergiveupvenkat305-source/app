class MeetingRow {
  final String id;
  final String shgId;
  final DateTime meetingDate;
  final String? meetingTime;
  final String? venue;
  final String? agenda;
  final String status;

  const MeetingRow({
    required this.id,
    required this.shgId,
    required this.meetingDate,
    this.meetingTime,
    this.venue,
    this.agenda,
    required this.status,
  });

  factory MeetingRow.fromRow(Map<String, dynamic> row) => MeetingRow(
        id: row['id'] as String,
        shgId: row['shg_id'] as String,
        meetingDate: DateTime.parse(row['meeting_date'] as String),
        meetingTime: row['meeting_time'] as String?,
        venue: row['venue'] as String?,
        agenda: row['agenda'] as String?,
        status: row['status'] as String,
      );
}

class ActionItemRow {
  final String id;
  final String task;
  final String? ownerName;
  final DateTime? dueDate;
  final bool done;

  const ActionItemRow({required this.id, required this.task, this.ownerName, this.dueDate, required this.done});

  factory ActionItemRow.fromRow(Map<String, dynamic> row) => ActionItemRow(
        id: row['id'] as String,
        task: row['task'] as String,
        ownerName: (row['profiles'] as Map<String, dynamic>?)?['name'] as String?,
        dueDate: row['due_date'] != null ? DateTime.parse(row['due_date'] as String) : null,
        done: row['done'] as bool? ?? false,
      );
}
