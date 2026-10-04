#!/usr/bin/env python
import os
import sys

if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend_project.settings')
    import backend_project.django_py314_compat  # noqa: F401
    try:
        import django
        from django.core.management import call_command, execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc

    if len(sys.argv) > 1 and sys.argv[1] == 'runserver':
        django.setup()
        call_command('migrate', interactive=False, verbosity=0)

    execute_from_command_line(sys.argv)
