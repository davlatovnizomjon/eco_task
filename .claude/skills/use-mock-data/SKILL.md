---
name: use-mock-data
description: Use mock data when the backend is not available or the UI must be built without a network connection. Covers the mock HTTP client, where mock JSON lives, and how to add an endpoint so the feature can later switch to the real API without touching repository code.
---

# Use Mock Data for UI Development

When developing the UI without a connection to the backend, simulate API responses with mock data —
**at the HTTP-client layer, never inside the repository or the bloc.** The repository must be written
exactly as it will be against the real API, so switching to the live backend is a one-line change.

## Step 0 — Map this onto the project

Find (or create) these three pieces and use the project's real names from here on:

1. **`<http client>`** — the single wrapped client every request goes through (e.g. a `DioClient`).
2. **`<mock client>`** — a subclass of `<http client>` that overrides the network methods to return
   local mock JSON instead of hitting the network (e.g. `MockdataClient extends DioClient`).
3. **`<mock data folder>`** — where the mock responses live, keyed by endpoint (e.g.
   `lib/network/mock_json_data/`), split by domain: `auth.dart`, `user.dart`, `order.dart`, ….

If the project has no mock client yet, create one in that shape — do not scatter `if (isMock)`
branches through repositories.

## Instructions

1. **Use the mock client in place of the real one.** Because `<mock client>` extends `<http client>`,
   the repository code is identical either way:

   ```dart
   // Choose the client from the environment / a config flag — the only place mock-ness is visible
   <http client> client = useMockData ? <mock client>() : <http client>();

   // The rest of the repository is unchanged
   final response = await client.get(Links.sendPhone);
   ```

2. **Store mock data as Dart maps keyed by the endpoint constant.** Files live in
   `<mock data folder>`, organised by category (`auth.dart`, `user.dart`, `order.dart`, …) so a mock
   is found the same way an endpoint is.

3. **Adding a new endpoint:**
   - Open the matching file in `<mock data folder>` (e.g. `auth.dart`).
   - Add the endpoint constant from the project's endpoint class (`Links` / `ApiLinks`) as the key and
     the JSON response as a Dart `Map`.
   - Mirror the **real** response envelope the client expects — the same status/message/data keys the
     wrapper checks — so error handling behaves identically against the mock and the live API.

   ```dart
   Links.newEndpoint: {
     "status": 200,
     "message": "success",
     "data": {"id": 1, "name": "New Data"}
   }
   ```

4. **Cover the failure paths too.** Add at least one mock that returns the API's error envelope, so
   the feature's error presentation is exercised before the backend exists.

5. **Mock data is temporary.** When the endpoint goes live, switch the client and verify the feature
   against the real API — the mock entry stays only as long as it is useful for offline UI work.
