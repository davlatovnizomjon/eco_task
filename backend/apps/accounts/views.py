from django.db.models import Q
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema, extend_schema_view
from rest_framework import generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.errors import DomainError
from apps.core.policies import Cap, Role, can

from . import services
from .models import AuthToken, User, hash_token
from .serializers import (
    LoginResponseSerializer,
    LoginSerializer,
    LoginUserSerializer,
    PasswordChangeSerializer,
    RefreshSerializer,
    TokenPairSerializer,
    UserBriefSerializer,
    UserCreateSerializer,
    UserSerializer,
    UserUpdateSerializer,
)
from .throttles import LoginThrottle, RefreshThrottle


class LoginView(APIView):
    """Sign in with username and password; returns a bearer token and the account."""

    authentication_classes: list = []
    permission_classes = [AllowAny]
    throttle_classes = [LoginThrottle]

    @extend_schema(tags=["auth"], request=LoginSerializer, responses={200: LoginResponseSerializer}, auth=[])
    def post(self, request):
        data = LoginSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        user, access, refresh = services.login(**data.validated_data, ip=request.META.get("REMOTE_ADDR", ""))
        return Response({"token": access, "refresh": refresh, "user": LoginUserSerializer(user).data})


class RefreshView(APIView):
    """Trade a refresh token for a new token pair. Needs no access token: that is what has expired."""

    authentication_classes: list = []
    permission_classes = [AllowAny]
    throttle_classes = [RefreshThrottle]

    @extend_schema(tags=["auth"], request=RefreshSerializer, responses={200: TokenPairSerializer}, auth=[])
    def post(self, request):
        data = RefreshSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        access, refresh = services.refresh_session(data.validated_data["refresh"])
        return Response({"token": access, "refresh": refresh})


class LogoutView(APIView):
    @extend_schema(tags=["auth"], request=None, responses={204: None})
    def post(self, request):
        raw = request.META.get("HTTP_AUTHORIZATION", "").split(" ")[-1]
        AuthToken.objects.filter(key_hash=hash_token(raw), user=request.user).update(revoked_at=timezone.now())
        return Response(status=status.HTTP_204_NO_CONTENT)


class MeView(APIView):
    @extend_schema(tags=["auth"], responses=UserSerializer)
    def get(self, request):
        return Response(UserSerializer(request.user).data)


class PasswordChangeView(APIView):
    @extend_schema(tags=["auth"], request=PasswordChangeSerializer, responses={200: TokenPairSerializer})
    def post(self, request):
        data = PasswordChangeSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        access, refresh = services.change_password(
            request.user, data.validated_data["old_password"], data.validated_data["new_password"]
        )
        return Response({"token": access, "refresh": refresh})


def _manages_accounts(user) -> bool:
    """The owner (every account) or an assistant (workers and clients): the people who see full account data."""
    return can(user, Cap.MANAGE_USERS) or can(user, Cap.MANAGE_STAFF)


def _visible_users(user):
    """Owner: everyone. Assistant: active workers and clients only. Others: nobody (use /auth/me/)."""
    if can(user, Cap.MANAGE_USERS):
        return User.objects.all()
    if user.role == Role.ASSISTANT:
        return User.objects.filter(role__in=[Role.WORKER, Role.CLIENT], is_active=True)
    return User.objects.none()


@extend_schema_view(
    get=extend_schema(
        tags=["users"],
        parameters=[
            OpenApiParameter("role", str, description="One role or a comma list, e.g. `WORKER` or `OWNER,ASSISTANT`."),
            OpenApiParameter("q", str, description="Case-insensitive search in username and full name."),
        ],
    ),
    post=extend_schema(tags=["users"], request=UserCreateSerializer, responses={201: UserSerializer}),
)
class UserListCreate(generics.ListCreateAPIView):
    def get_queryset(self):
        qs = _visible_users(self.request.user).order_by("id")
        params = self.request.query_params
        roles = [r.strip().upper() for r in params.get("role", "").split(",") if r.strip()]
        if roles:
            qs = qs.filter(role__in=roles)
        if params.get("q"):
            qs = qs.filter(Q(username__icontains=params["q"]) | Q(full_name__icontains=params["q"]))
        return qs

    def get_serializer_class(self):
        if self.request.method == "POST":
            return UserCreateSerializer
        return UserSerializer if _manages_accounts(self.request.user) else UserBriefSerializer

    def create(self, request, *args, **kwargs):
        if not _manages_accounts(request.user):
            raise DomainError("You may not create users.", "forbidden", 403)
        data = UserCreateSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        user = services.create_user(request.user, **data.validated_data)
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["users"]),
    patch=extend_schema(tags=["users"], request=UserUpdateSerializer, responses={200: UserSerializer}),
)
class UserDetail(generics.RetrieveUpdateAPIView):
    http_method_names = ["get", "patch", "delete", "head", "options"]

    def get_queryset(self):
        return _visible_users(self.request.user)  # unknown or unauthorized ids both give 404 (no IDOR oracle)

    def get_serializer_class(self):
        return UserSerializer if _manages_accounts(self.request.user) else UserBriefSerializer

    @extend_schema(tags=["users"], responses={200: dict})
    def delete(self, request, *args, **kwargs):
        target = self.get_object()
        if not _manages_accounts(request.user):
            raise DomainError("You may not delete users.", "forbidden", 403)
        return Response({"result": services.delete_user(request.user, target)})

    def partial_update(self, request, *args, **kwargs):
        target = self.get_object()
        if not _manages_accounts(request.user):
            raise DomainError("You may not modify users.", "forbidden", 403)
        data = UserUpdateSerializer(data=request.data, partial=True)
        data.is_valid(raise_exception=True)
        return Response(UserSerializer(services.update_user(request.user, target, data.validated_data)).data)
