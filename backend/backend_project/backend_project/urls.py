from django.contrib import admin
from django.http import JsonResponse
from django.urls import path, include
from rest_framework import permissions
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
 

schema_view = get_schema_view(
    openapi.Info(
        title="Transportation App API",
        default_version='v1',
        description="Transportation App API",
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

def api_root(_request):
    return JsonResponse(
        {
            'name': 'Transportation App API',
            'docs': '/swagger/',
            'admin': '/admin/',
            'auth': {'obtainToken': 'POST /api/token/', 'refresh': 'POST /api/token/refresh/'},
            'api': '/api/',
        }
    )


urlpatterns = [
    path('', api_root),
    path('admin/', admin.site.urls),
    path('api/', include('core.urls')),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
]
