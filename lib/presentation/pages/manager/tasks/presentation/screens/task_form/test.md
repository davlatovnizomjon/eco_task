# Task form (manager) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TeamRepository.getUsers` — GET `users?role=staff`

- [ ] Success: the staff directory → 200 with assignable people; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: the assignee picker offers every active staff member (workers and managers) and the company's clients.

### `TasksRepository.createTask` / `editTask` — POST `tasks` / PUT `tasks/{id}`

- [ ] Success: a valid draft (title, due, assignees with optional quotas, priority, reward) → 200 with the created/updated task and a new inbox entry for every assignee except the creator; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Parameter error: an empty title or no assignees is rejected locally before any request → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Values: editing keeps each assignee's reported `done` progress; the reward is sent as an integer without separators.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Create a task end to end: name, assignees via the sheet (checkbox rows), per-assignee shares, deadline date and time via the sheet, priority switch with icons, reward, description, expected result; edit an existing task from its details.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] The date and time fields sit side by side and both open the same date-and-time sheet; the sheet has quick day chips, the month grid (past days disabled), time chips and a confirm button with the chosen moment.
- [ ] The assignee sheet lists “O‘zimga” first, then staff with their active-task counts; selected rows show a green checkbox; the button shows the selected count.
- [ ] Create mode is the five-step wizard (boards 2.3–2.3d): 1 client type (+ organization or person name), 2 about (name, description, price with so‘m / $), 3 deadline and address, 4 assignees, 5 review; a progress line of five segments, the step title and “Keyingi →” / “Yaratish va yuborish”; back (bar or system) steps back, then leaves.
- [ ] Validation per step: an organization without a name (1), an empty task name (2) and no assignee (4) block “Keyingi” with the shared error dialog and a red field; nothing is red before the first attempt. On success the “Vazifa yaratildi” dialog appears and closes the screen.
- [ ] Not built: photo upload on step 3 (no file service yet); edit mode keeps the single-page form.
- [ ] Edit mode (boards 2.6 edit, 2.6 assignees): one page with the client type and name, task name, description, price with so‘m / $, deadline and address (the wizard's fields), then an assignees row (stacked avatars + “N ta ijrochi”) opening a picker sheet with role pills and a “Tanlash” button; “Saqlash” saves. The assignees border turns red only after a failed save.
- [ ] Opening an existing task fills client, address and currency from it; saving sends them back.

## 4. Logical/Business Test

- [ ] An empty name or no assignee blocks saving with the first error shown in the dialog.
- [ ] After saving, the list and the details reflect the change on return.
