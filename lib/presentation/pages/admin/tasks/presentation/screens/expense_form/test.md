# Expense form (worker) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.addExpense` — POST `tasks/{id}/expenses`

- [ ] Success: `{amount, kind, note, hasReceipt}` → 200 with the task with a new `pending` expense; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Parameter error: amount 0 or empty is rejected locally → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Values: the expense appears in the boss review queue and the boss gets a `expense` inbox entry with the formatted amount.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Add an expense with and without a receipt; it shows in the worker's task details as pending and in the boss review queue.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Amount field groups thousands and shows `($)`; kind chips (transport, material, other) select one; the receipt tile adds/removes a placeholder photo; the empty-amount error is red only after the first submit.

## 4. Logical/Business Test

- [ ] Without a receipt the expense can be sent but is flagged “no receipt” for the boss.
- [ ] Only workers assigned to the task can reach this form.
