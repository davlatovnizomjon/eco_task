import '../common/api_cache.dart';
import '../common/api_links.dart';
import '../dto/models/expense_entry.dart';
import '../dto/models/expense_totals.dart';
import '../dto/models/paged_list.dart';

import 'package:eco_task/infrastructure/common/dio_client.dart';

/// Expense lists, money totals and the approve/reject/pay actions.
class ExpensesRepository {
  /// Rows per page of the expenses list.
  static const pageSize = 20;

  /// Cached first page of the [filter] tab, or an empty page.
  PagedList<ExpenseEntry> cachedExpenses(String filter) =>
      ApiCache.read<PagedList<ExpenseEntry>>('exp|$filter') ?? const PagedList();

  /// Loads page [page] of the [filter] tab (`pending|approved|rejected|paid`).
  Future<PagedList<ExpenseEntry>> getExpenses(String filter, {int page = 1}) async {
    final response = await dioClient.get(
      ApiLinks.expenses,
      queryParameters: {'filter': filter, 'page': page, 'pageSize': pageSize},
    );
    final result = PagedList.fromJson(response.data as Map<String, dynamic>, ExpenseEntry.fromJson);
    return page == 1 ? ApiCache.write('exp|$filter', result) : result;
  }

  /// Cached totals, or null before the first load.
  ExpenseTotals? cachedTotals() => ApiCache.read<ExpenseTotals>('exp|totals');

  /// Loads the money totals and per-tab counters.
  Future<ExpenseTotals> getTotals() async {
    final response = await dioClient.get(ApiLinks.expensesSummary);
    return ApiCache.write('exp|totals', ExpenseTotals.fromJson(response.data as Map<String, dynamic>));
  }

  /// Approves the expense for [amount], or rejects it when [amount] is null.
  Future<void> review(String taskId, String expenseId, {int? amount}) async {
    await dioClient.post(ApiLinks.expenseReview(taskId, expenseId), data: {if (amount != null) 'amount': amount});
    ApiCache.invalidate();
  }

  /// Marks an approved expense as paid out.
  Future<void> pay(String taskId, String expenseId) async {
    await dioClient.post(ApiLinks.expensePay(taskId, expenseId));
    ApiCache.invalidate();
  }
}
