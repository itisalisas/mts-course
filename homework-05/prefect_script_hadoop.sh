#!/bin/bash

set -xe

WORKING_DIR=/tmp/prefect

source .venv/bin/activate

pip install -U pip
pip install prefect
python $WORKING_DIR/python/prefect_flow.py
