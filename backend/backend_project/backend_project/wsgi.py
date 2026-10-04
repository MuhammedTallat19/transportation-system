import os

import backend_project.django_py314_compat  # noqa: F401
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend_project.settings')
application = get_wsgi_application()
