import '../../../domain/common/enums/expense_kind.dart';
import '../../../domain/common/enums/expense_status.dart';
import 'user_ref.dart';

/// A cost a worker entered against a task.
class ExpenseModel {
  /// Unique id inside its task.
  final String id;

  /// The worker who entered it.
  final UserRef user;

  /// Free-text note, e.g. "Transport — ko'chatlarni tashish".
  final String note;

  /// Amount the worker entered.
  final int amount;

  /// Amount the boss confirmed; 0 until approved.
  final int approvedAmount;

  /// Category picked by the worker.
  final ExpenseKind kind;

  /// Review state.
  final ExpenseStatus status;

  /// True when a receipt photo was attached.
  final bool hasReceipt;

  /// True once the approved amount was paid out to the worker.
  final bool isPaid;

  /// When it was entered.
  final DateTime at;

  /// Builds an expense from its parts.
  const ExpenseModel({
    required this.id,
    required this.user,
    required this.note,
    required this.amount,
    required this.at,
    this.approvedAmount = 0,
    this.kind = ExpenseKind.other,
    this.status = ExpenseStatus.pending,
    this.hasReceipt = true,
    this.isPaid = false,
  });

  /// Parses the API object.
  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: '${json['id']}',
    user: UserRef.fromJson(json['user'] as Map<String, dynamic>),
    note: '${json['note'] ?? ''}',
    amount: (json['amount'] as num).toInt(),
    approvedAmount: (json['approvedAmount'] as num?)?.toInt() ?? 0,
    kind: ExpenseKind.fromJson(json['kind']),
    status: ExpenseStatus.fromJson(json['status']),
    hasReceipt: json['hasReceipt'] as bool? ?? false,
    isPaid: json['isPaid'] as bool? ?? false,
    at: DateTime.parse('${json['at']}'),
  );

  /// Serializes the expense.
  Map<String, dynamic> toJson() => {
    'id': id,
    'user': user.toJson(),
    'note': note,
    'amount': amount,
    'approvedAmount': approvedAmount,
    'kind': kind.name,
    'status': status.name,
    'hasReceipt': hasReceipt,
    'isPaid': isPaid,
    'at': at.toIso8601String(),
  };

  /// Copy with a new review [status], [approvedAmount] or [isPaid] flag.
  ExpenseModel copyWith({ExpenseStatus? status, int? approvedAmount, bool? isPaid}) => ExpenseModel(
    id: id,
    user: user,
    note: note,
    amount: amount,
    at: at,
    kind: kind,
    hasReceipt: hasReceipt,
    status: status ?? this.status,
    approvedAmount: approvedAmount ?? this.approvedAmount,
    isPaid: isPaid ?? this.isPaid,
  );
}
