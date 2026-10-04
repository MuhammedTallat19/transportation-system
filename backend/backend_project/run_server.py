import os
import sys

if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend_project.settings')
    import backend_project.django_py314_compat  # noqa: F401
    import django
    from django.core.management import call_command, execute_from_command_line

    django.setup()
    call_command('migrate', interactive=False, verbosity=0)

    sys.argv = ['manage.py', 'runserver', '0.0.0.0:8000']
    execute_from_command_line(sys.argv)
