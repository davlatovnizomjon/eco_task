"""OpenAPI description of the bearer-token authentication, so Swagger UI shows an "Authorize" button."""

from drf_spectacular.extensions import OpenApiAuthenticationExtension


class BearerTokenScheme(OpenApiAuthenticationExtension):
    target_class = "apps.accounts.authentication.BearerTokenAuthentication"
    name = "bearerAuth"

    def get_security_definition(self, auto_schema):
        return {
            "type": "http",
            "scheme": "bearer",
            "description": "Token from `POST /api/v1/auth/login/`. Send as `Authorization: Bearer <token>`.",
        }
