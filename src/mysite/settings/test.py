from base import *
import os

# Database
# https://docs.djangoproject.com/en/1.8/ref/settings/#databases
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.environ.get('MYSQL_DATABASE','app_db'),
        'USER': os.environ.get('MYSQL_USER','dbuser'),
        'PASSWORD': os.environ.get('MYSQL_PASSWORD','password'),
        'HOST': os.environ.get('MYSQL_HOST','db'),
        'PORT': os.environ.get('MYSQL_PORT','3306'),
    }
}