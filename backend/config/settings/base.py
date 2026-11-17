"""Settings shared by every environment. Secrets always come from the environment."""

from pathlib import Path

from config import env

BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = env.get("DJANGO_SECRET_KEY")
DEBUG = False
ALLOWED_HOSTS = env.csv("DJANGO_ALLOWED_HOSTS")

INSTALLED_APPS = [
    "apps.core.admin_config.EcoAdminConfig",  # django.contrib.admin with the policy-gated site
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "channels",
    "rest_framework",
    "drf_spectacular",
    "apps.core",
    "apps.audit",
    "apps.accounts",
    "apps.projects",
    "apps.tasks",
    "apps.client_requests",
    "apps.notifications",
    "apps.chat",
    "apps.files",
    "apps.finance",
    "apps.reports",
    "apps.releases",
    "apps.legal",
    "apps.support",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",  # serves the admin's static files (uvicorn does not)
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
ASGI_APPLICATION = "config.asgi.application"
WSGI_APPLICATION = "config.wsgi.application"
AUTH_USER_MODEL = "accounts.User"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ]
        },
    }
]

# --- Admin site and static files ----------------------------------------------------------
# The admin lives under a configurable prefix so it is not at the guessable default in production.
ADMIN_URL = env.get("ADMIN_URL", "admin/").strip("/") + "/"
STATIC_URL = "static/"
STATIC_ROOT = Path(env.get("STATIC_ROOT", str(BASE_DIR / "staticfiles")))

# --- Database -----------------------------------------------------------------------------
# PostgreSQL is the authoritative store. SQLite exists only for quick local/test runs.
if env.get("DB_ENGINE", "postgres") == "sqlite":
    DATABASES = {"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": env.get("DB_NAME", ":memory:")}}
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": env.get("DB_NAME"),
            "USER": env.get("DB_USER"),
            "PASSWORD": env.get("DB_PASSWORD"),
            "HOST": env.get("DB_HOST", "localhost"),
            "PORT": env.get("DB_PORT", "5432"),
            "CONN_MAX_AGE": env.integer("DB_CONN_MAX_AGE", 60),
            "CONN_HEALTH_CHECKS": True,
            "OPTIONS": {"connect_timeout": 5},
        }
    }
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
ATOMIC_REQUESTS = False  # transactions are opened explicitly in services

# --- Redis / channels / cache -------------------------------------------------------------
REDIS_URL = env.get("REDIS_URL", "")
if REDIS_URL:
    CHANNEL_LAYERS = {"default": {"BACKEND": "channels_redis.core.RedisChannelLayer", "CONFIG": {"hosts": [REDIS_URL]}}}
    CACHES = {"default": {"BACKEND": "django.core.cache.backends.redis.RedisCache", "LOCATION": REDIS_URL}}
else:  # development / tests only; production settings refuse to start without REDIS_URL
    CHANNEL_LAYERS = {"default": {"BACKEND": "channels.layers.InMemoryChannelLayer"}}
    CACHES = {"default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache"}}

# --- Authentication -----------------------------------------------------------------------
LOGIN_MAX_ATTEMPTS = env.integer("LOGIN_MAX_ATTEMPTS", 5)  # wrong passwords in a row before the lock
LOGIN_LOCK_SECONDS = env.integer("LOGIN_LOCK_SECONDS", 5 * 60)  # how long the lock lasts
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.Argon2PasswordHasher",
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",
]
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator", "OPTIONS": {"min_length": 12}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]
API_ACCESS_TOKEN_MINUTES = env.integer("API_ACCESS_TOKEN_MINUTES", 60)
API_REFRESH_TOKEN_DAYS = env.integer("API_REFRESH_TOKEN_DAYS", 14)

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": ["apps.accounts.authentication.BearerTokenAuthentication"],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticated"],
    "DEFAULT_PAGINATION_CLASS": "apps.core.pagination.StandardPagination",
    "PAGE_SIZE": 20,
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_THROTTLE_CLASSES": ["rest_framework.throttling.UserRateThrottle"],
    "DEFAULT_THROTTLE_RATES": {"user": "600/min", "login": "10/min", "refresh": "30/min", "upload": "30/min"},
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
    "DEFAULT_PARSER_CLASSES": ["rest_framework.parsers.JSONParser"],
    "EXCEPTION_HANDLER": "apps.core.errors.exception_handler",
}
SPECTACULAR_SETTINGS = {
    "TITLE": "Eco Tasks API",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
    "COMPONENT_SPLIT_REQUEST": True,
    "ENUM_NAME_OVERRIDES": {
        "TaskStatusEnum": "apps.tasks.models.Status",
        "ConversationKindEnum": "apps.chat.models.Kind",
        "RequestStatusEnum": "apps.client_requests.models.Status",
        "RequestKindEnum": "apps.client_requests.models.Kind",
    },
    "SCHEMA_PATH_PREFIX": r"/api/v1",
    "TAGS": [
        {"name": "auth", "description": "Sign-in, session and password."},
        {"name": "users", "description": "Company and client accounts."},
        {"name": "projects", "description": "Projects that group tasks."},
        {"name": "tasks", "description": "Tasks, assignees, status transitions, history and comments."},
        {"name": "requests", "description": "Client service requests (delivery, planting, care)."},
        {"name": "chat", "description": "Conversations and messages (REST)."},
        {"name": "notifications", "description": "Per-user inbox."},
        {"name": "audit", "description": "Audit log (owner only)."},
    ],
    "DESCRIPTION": (
        "REST API of the Eco Tasks backend.\n\n"
        "**Errors** always use `{\"error\": {\"code\": \"...\", \"detail\": ...}}`.\n\n"
        "**Real-time chat** is a WebSocket, not part of OpenAPI: connect to "
        "`/ws/chat/<conversation_id>/` with the subprotocols `bearer, <token>`. Client frames: "
        "`{type: message.send, body, client_msg_id}`, `{type: message.read, message_id}`, `{type: ping}`. "
        "Server frames: `presence.snapshot`, `presence`, `message.new`, `message.ack`, `message.read`, "
        "`revoked`, `error`, `pong`."
    ),
}

# --- Uploads ------------------------------------------------------------------------------
# Private storage, never under a statically served path; downloads go through authorized views.
PRIVATE_MEDIA_ROOT = Path(env.get("PRIVATE_MEDIA_ROOT", str(BASE_DIR / "private_media")))
UPLOAD_MAX_BYTES = env.integer("UPLOAD_MAX_BYTES", 10 * 1024 * 1024)
DATA_UPLOAD_MAX_MEMORY_SIZE = 12 * 1024 * 1024
FILE_UPLOAD_MAX_MEMORY_SIZE = 2 * 1024 * 1024

# --- Business policy ----------------------------------------------------------------------
CURRENCY = env.get("CURRENCY", "UZS")  # single-currency policy; amounts are Decimal(14, 2)
TASK_COMPLETION_REQUIRES_APPROVAL = env.boolean("TASK_COMPLETION_REQUIRES_APPROVAL", True)
CHAT_MAX_MESSAGE_CHARS = 4000
CALL_RING_SECONDS = env.integer("CALL_RING_SECONDS", 45)  # an unanswered call becomes MISSED after this long
CHAT_MESSAGES_PER_MINUTE = env.integer("CHAT_MESSAGES_PER_MINUTE", 60)
WS_MAX_CONNECTIONS_PER_USER = env.integer("WS_MAX_CONNECTIONS_PER_USER", 5)
WS_ALLOWED_ORIGINS = env.csv("WS_ALLOWED_ORIGINS")
# Firebase service-account JSON used to send push notifications; empty = push disabled.
FIREBASE_CREDENTIALS_FILE = env.get("FIREBASE_CREDENTIALS_FILE", "")

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "json": {"format": '{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","message":"%(message)s"}'}
    },
    "handlers": {"console": {"class": "logging.StreamHandler", "formatter": "json"}},
    "root": {"handlers": ["console"], "level": env.get("LOG_LEVEL", "INFO")},
}

# Backup settings are read by scripts/backup_db.sh and apps.core.management commands.
BACKUP_DIR = env.get("BACKUP_DIR", str(BASE_DIR / "backups"))
