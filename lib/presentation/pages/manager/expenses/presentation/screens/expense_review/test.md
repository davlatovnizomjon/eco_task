# Expense review (boss) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getTask` — GET `tasks/{id}`

- [ ] Success: the task holding the expense → 200 with the expense with note, amount, receipt flag; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.

### `ExpensesRepository.review` — POST `tasks/{id}/expenses/{eid}/review`

- [ ] Success: `{amount: 180}` for a 200 expense, and an empty body to reject → 200 with status `approved` with `approvedAmount` 180, or `rejected`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Parameter error: amount 0 or above the entered amount → 400 `detail` shown in the dialog → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Values: approving notifies the worker with the approved and entered amounts; the task's approved sum reflects it.

## 2. Mobile/Web Integration Test

- [ ] Approve for a smaller amount and reject another; return to the list and see both leave the pending tab.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The approve button label shows the typed amount formatted; the amount field is prefilled with the entered amount; an invalid amount is red only after the first decision attempt; a missing receipt shows the warning banner.

## 4. Logical/Business Test

- [ ] The approved amount can never exceed the entered one nor be zero.
