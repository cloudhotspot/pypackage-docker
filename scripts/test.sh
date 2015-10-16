#!/bin/bash
# Activate virtual environment
. /appenv/bin/activate
pip install .[test]
exec $@