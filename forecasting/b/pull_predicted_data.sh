#!/bin/bash

# $1 is credential file location; $2 is the helper script location; $3 is target directory for downloads
GOOGLE_APPLICATION_CREDENTIALS=$1 python3 $2 --dir $3
