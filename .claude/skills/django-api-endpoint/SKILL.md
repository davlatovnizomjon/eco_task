---
name: django-api-endpoint
description: >-
  Step-by-step recipe for adding or changing a REST endpoint in the Eco Tasks backend: model/migration, serializers,
  service function, access queryset, APIView, URL, audit/notification, OpenAPI. Use when the user asks for a new
  API route, a new field on an existing resource, a new status transition or a new capability. Follow
  `django-project-rules` for the rules; this skill is the order of work and the code templates.
---

# Adding an endpoint — recipe

Reference implementation: `apps/tasks/` (`models.py`, `serializers.py`, `services.py`, `access.py`,
`transitions.py`, `views.py`, `urls.py`). Read it before writing, and copy its shape.

## Order of work

1. **Policy** — does it need a new `Cap`? Add it to `Cap` + `ROLE_CAPS` in `apps/core/policies.py`.
2. **Model** — add fields/constraints/indexes; create the migration (`python manage.py makemigrations <app>`).
3. **Access** — if the resource is user-scoped, extend/add `visible_<resource>(user)` in `access.py`.
4. **Serializers** — `XCreateSerializer` / `XUpdateSerializer` (explicit writable fields, `partial=True` for PATCH,
   optional `version` for optimistic concurrency) and an output `XSerializer` (all read-only).
5. **Service** — one function per use case.
6. **View + URL** — thin `APIView` classes; register in the app's `urls.py` (already included in
   `apps/core/api_urls.py`; add an `include` there only for a brand-new app + `INSTALLED_APPS`).
7. **Tests** — `django-testing` skill (success, forbidden role, foreign id -> 404, invalid input, conflict).
8. **Docs/test notes** — update OpenAPI annotations if the shape is non-obvious (`extend_schema`) and tell the user
   which Flutter DTO / mock JSON must change.

## Service template

```python
@transaction.atomic
def do_thing(actor: User, thing_id, data: dict, version: int | None = None) -> Thing:
    thing = Thing.objects.select_for_update().get(pk=thing_id)
    if not can(actor, Cap.MANAGE_THINGS):
        raise DomainError("You may not change things.", "forbidden", 403)
    _check_version(thing, version)               # 409 version_conflict
    if thing.status in CLOSED:
        raise DomainError("Closed things cannot be edited.", "thing_closed", 409)
    for field, value in data.items():
        if field in EDITABLE:                    # whitelist, never setattr blindly
            setattr(thing, field, value)
    thing.version += 1
    thing.save()
    record(actor, "thing.updated", thing, fields=sorted(data))
    notify(audience, "thing.updated", f"Thing changed: {thing.title}", task=None, exclude=actor)
    return thing
```

## View template

```python
class ThingDetail(APIView):
    def get(self, request, pk):
        return Response(ThingSerializer(get_thing(request, pk), context={"request": request}).data)

    def patch(self, request, pk):
        get_thing(request, pk)                                   # 404 before anything else (IDOR)
        data = ThingUpdateSerializer(data=request.data, partial=True)
        data.is_valid(raise_exception=True)
        changes = dict(data.validated_data)
        version = changes.pop("version", None)
        services.update_thing(request.user, pk, changes, version)
        return Response(ThingSerializer(get_thing(request, pk), context={"request": request}).data)
```

- `get_thing` = `get_object_or_404(visible_things(request.user)..., pk=pk)` with `select_related`/`prefetch_related`
  to avoid N+1.
- Role-gated routes add `permission_classes = [has_cap(Cap.X)]`.
- Lists: filter only on whitelisted params, `order_by(whitelisted or default, "-id")`, `.distinct()` after joins,
  paginate with `StandardPagination().paginate_queryset` + `get_paginated_response`. Response is
  `{count, next, previous, results}`.
- Create returns `201`; re-read through the visible queryset so the response matches what the user may see.

## Status machines

Add moves to the `RULES` table in `transitions.py` (`(from, to) -> {actor kinds}`), list reason-required moves in
`REASON_REQUIRED`, and keep DB `CheckConstraint`s consistent (e.g. `completed_at` only when `COMPLETED`). The service
`transition()` is the only writer of `status`.

## Do not

- Put rules in serializers/views, compare `user.role` inline, or use `fields = "__all__"`.
- Return different errors for "missing" vs "forbidden" ids.
- Save without `record()` for state-changing operations the owner may need to audit.
- Add an unpaginated list endpoint or an unbounded `ordering`/filter parameter.
