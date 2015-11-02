from base import *
import os

# Installed Apps
INSTALLED_APPS += ('django_nose', )
TEST_RUNNER = 'django_nose.NoseTestSuiteRunner'
NOSE_ARGS = [
  '--with-coverage',  # activate coverage report
  '--with-doctest',  # activate doctest: find and run docstests
  '--verbosity=2',   # verbose output 
  '--with-xunit',    # enable XUnit plugin
  '--xunit-file=xunittest.xml',  # the XUnit report file
  '--cover-html',     # produle XML coverage info
  '--cover-html-dir=reports',  # the coverage info file
  '--cover-package=polls',
  '--cover-erase'
]

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