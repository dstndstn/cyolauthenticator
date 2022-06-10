#! /bin/bash
cd /
jupyterhub -f jup-config.py >> jupyterhub.log 2>&1
