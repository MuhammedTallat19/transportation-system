import os
from pathlib import Path
from datetime import timedelta

import environ


# =========================================================
# BASE DIRECTORY
# =========================================================

BASE_DIR = Path(__file__).resolve().parent.parent


# =========================================================
# ENVIRONMENT
# =========================================================

env = environ.Env(
    DEBUG=(bool, False),

    SECRET_KEY=(str, 'replace-me'),

    DB_NAME=(str, 'gstms_db'),
    DB_USER=(str, 'postgres'),
    DB_PASSWORD=(str, '1999'),
    DB_HOST=(str, '127.0.0.1'),
    DB_PORT=(str, '1999'),

    REDIS_URL=(str, 'redis://127.0.0.1:6379/1'),

    USE_SQLITE=(bool, True),
)

env.read_env(BASE_DIR / '.env')


# =========================================================
# SECURITY
# =========================================================

SECRET_KEY = env('SECRET_KEY')

DEBUG = env('DEBUG')

ALLOWED_HOSTS = env.list(
    'ALLOWED_HOSTS',
    default=['*']
)


# =========================================================
# INSTALLED APPS
# =========================================================

INSTALLED_APPS = [
    # Django
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Third-party
    'corsheaders',
    'rest_framework',
    'drf_yasg',

    # Local
    'core',
]


# =========================================================
# MIDDLEWARE
# =========================================================

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',

    'django.middleware.security.SecurityMiddleware',

    'django.contrib.sessions.middleware.SessionMiddleware',

    'django.middleware.common.CommonMiddleware',

    'django.middleware.csrf.CsrfViewMiddleware',

    'django.contrib.auth.middleware.AuthenticationMiddleware',

    'django.contrib.messages.middleware.MessageMiddleware',

    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]


# =========================================================
# URL / WSGI
# =========================================================

ROOT_URLCONF = 'backend_project.urls'

WSGI_APPLICATION = 'backend_project.wsgi.application'


# =========================================================
# TEMPLATES
# =========================================================

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',

        'DIRS': [],

        'APP_DIRS': True,

        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]


# =========================================================
# DATABASE
# =========================================================

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',

        'NAME': env('DB_NAME'),

        'USER': env('DB_USER'),

        'PASSWORD': env('DB_PASSWORD'),

        'HOST': env('DB_HOST'),

        'PORT': env('DB_PORT'),
    }
}


# =========================================================
# OPTIONAL SQLITE FALLBACK
# =========================================================

USE_SQLITE = env.bool(
    'USE_SQLITE',
    default=True
)

if USE_SQLITE:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }


# =========================================================
# DJANGO REST FRAMEWORK
# =========================================================

REST_FRAMEWORK = {

    # JWT Authentication
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),

    # All APIs require authentication by default
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),

    # Optional
    'DEFAULT_RENDERER_CLASSES': (
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ),
}


# =========================================================
# SIMPLE JWT
# =========================================================

SIMPLE_JWT = {

    # Access Token
    'ACCESS_TOKEN_LIFETIME': timedelta(
        minutes=30
    ),

    # Refresh Token
    'REFRESH_TOKEN_LIFETIME': timedelta(
        days=7
    ),

    # Refresh configuration
    'ROTATE_REFRESH_TOKENS': False,

    'BLACKLIST_AFTER_ROTATION': False,

    # Authorization header
    'AUTH_HEADER_TYPES': (
        'Bearer',
    ),

    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',

    # User identification
    'USER_ID_FIELD': 'id',

    'USER_ID_CLAIM': 'user_id',
}


# =========================================================
# SWAGGER / DRF-YASG
# =========================================================

SWAGGER_SETTINGS = {

    # Disable Django session authentication
    'USE_SESSION_AUTH': False,

    # JWT Bearer authentication
    'SECURITY_DEFINITIONS': {

        'Bearer': {
            'type': 'apiKey',

            'name': 'Authorization',

            'in': 'header',

            'description': (
                'JWT Authorization header. '
                'Example: Bearer <access_token>'
            ),
        },
    },

    # Apply Bearer authentication globally
    'SECURITY_REQUIREMENTS': [
        {
            'Bearer': []
        }
    ],

    # Swagger UI
    'DISPLAY_OPERATION_ID': True,

    'DEFAULT_MODEL_RENDERING': 'example',

    'DEFAULT_INFO': 'Transportation App API',
}


# =========================================================
# AUTH USER MODEL
# =========================================================

AUTH_USER_MODEL = 'core.User'


# =========================================================
# PASSWORD VALIDATION
# =========================================================

AUTH_PASSWORD_VALIDATORS = [

    {
        'NAME': (
            'django.contrib.auth.password_validation.'
            'UserAttributeSimilarityValidator'
        ),
    },

    {
        'NAME': (
            'django.contrib.auth.password_validation.'
            'MinimumLengthValidator'
        ),
    },

    {
        'NAME': (
            'django.contrib.auth.password_validation.'
            'CommonPasswordValidator'
        ),
    },

    {
        'NAME': (
            'django.contrib.auth.password_validation.'
            'NumericPasswordValidator'
        ),
    },
]


# =========================================================
# INTERNATIONALIZATION
# =========================================================

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# =========================================================
# STATIC FILES
# =========================================================

STATIC_URL = 'static/'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

MIGRATION_MODULES = {}


# =========================================================
# REDIS CACHE
# =========================================================

CACHES = {

    'default': {

        'BACKEND': 'django_redis.cache.RedisCache',

        'LOCATION': env('REDIS_URL'),

        'OPTIONS': {
            'CLIENT_CLASS': (
                'django_redis.client.DefaultClient'
            ),
        },
    },
}


# =========================================================
# CORS
# =========================================================

CORS_ALLOWED_ORIGINS = env.list(
    'CORS_ALLOWED_ORIGINS',

    default=[
        'http://localhost:52527',
        'http://127.0.0.1:52527',

        'http://localhost:62751',
        'http://127.0.0.1:62751',

        'http://localhost:3000',

        'http://localhost:8080',

        'http://localhost:5173',
        'http://localhost:8000',
        'http://127.0.0.1:8000',
    ]
)

CORS_ALLOWED_ORIGIN_REGEXES = [
    r'^http://localhost(:\d+)?$',
    r'^http://127\.0\.0\.1(:\d+)?$',
]

CORS_ALLOW_CREDENTIALS = True