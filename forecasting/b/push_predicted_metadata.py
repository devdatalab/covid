# push predicted covid variable metadata to DDL AWS bucket (web server)
# in practice this is just the most recent rt_pred date from the latest run in a js object
# this will then be used as the basis for the choropleth in the web app

# note: you need the aws cli and an operational config for this to work (currently only TL has this)
# but can easily set up for others

import json
import requests
import argparse
import boto3
import os

# initialize args
parser = argparse.ArgumentParser()
parser.add_argument("--file", type=str)
args = parser.parse_args()

# pull file input into python obj
pushfile = f'{args.file}'
fname = os.path.basename(pushfile)

##########################
# upload new zips to AWS # 
##########################

# status report
print(f'pushing data from {pushfile} to AWS')

# initialize the boto s3 resource
s3 = boto3.resource('s3')

# execute AWS command to push the new zip file to S3.
# This requires your aws cli be configured properly, and depends on the current bucket subdirectory configuration
data = open(pushfile, 'rb')
s3.Bucket('shrug-assets-ddl').put_object(Key='static/main/assets/other/' + fname, Body=data, ACL='public-read')
