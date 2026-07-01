/// A pending idle/overrun prompt the worker must respond to before
/// continuing — set by the flag_idle_sessions / flag_overdue_jobcards
/// scheduler jobs on the backend (Worker Session.pending_prompt).
class WorkerPrompt {
  final String type; // "Idle" | "Overrun"
  final String message;
  final String? reference;

  const WorkerPrompt({
    required this.type,
    required this.message,
    this.reference,
  });

  factory WorkerPrompt.fromJson(Map<String, dynamic> json) => WorkerPrompt(
        type: json['type']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        reference: json['reference']?.toString(),
      );
}
