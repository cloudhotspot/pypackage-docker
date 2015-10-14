#!/bin/bash
. /appenv/bin/activate
pip install .[test]
exec $@