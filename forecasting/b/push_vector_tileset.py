# take tippecanoe vector tileset and push to mapbox
# see: https://docs.mapbox.com/api/maps/uploads/
# this requires mapbox credentials, which are defined in the YAML config for this project
# resulting tileset will have the tileset ID of devdatalab.rural-data-portal in mapbox studio

import json
import requests
import argparse
import boto3

# initialize args
parser = argparse.ArgumentParser()
parser.add_argument("--token", type=str)
parser.add_argument("--file", type=str)
args = parser.parse_args()


##########################
# Request S3 Credentials #
##########################

# retrieve S3 credentials. mapbox access token must be passed as an argument
params = (
    ('access_token', f'{args.token}'),
)
response = requests.post('https://api.mapbox.com/uploads/v1/devdatalab/credentials', params=params)
json_data = response.json() if response and response.status_code == 200 else None

# process the JSON response to pull necessary fields
bucket = json_data['bucket']
key = json_data['key']
url = json_data['url']
accessKeyId = json_data['accessKeyId']
secretAccessKey = json_data['secretAccessKey']
sessionToken = json_data['sessionToken']
key = json_data['key']

# define username and vector tileset name
username = 'devdatalab'
tileset_name = 'covid-forecasting'


##########################
# Upload to staging area #
##########################

# iniatialize AWS session with temp credentials
session = boto3.Session(
    aws_access_key_id = accessKeyId,
    aws_secret_access_key = secretAccessKey,
    aws_session_token = sessionToken,
)

# initialize the boto s3 resource
s3 = session.resource('s3')

# upload file to Mapbox's S3 staging bucket
#aws s3 cp f'{args.token}' s3://{bucket}/{key} --region us-east-1
data = open(f'{args.file}', 'rb')
s3.Bucket(bucket).put_object(Key=key, Body=data)


###########################
# Create upload to Mapbox #
###########################

# define the API call and initiate upload
headers = {
    'Content-Type': 'application/json',
    'Cache-Control': 'no-cache',
}
data = '{ "url": ' + f'"{url}"' + ', "tileset": ' + f'"{username}.{tileset_name}"' + ' }' # awkward bc fstrings can't handle literal colons
response = requests.post('https://api.mapbox.com/uploads/v1/devdatalab', headers=headers, params=params, data=data)

# get upload ID from the response
json_data = response.json() if response and response.status_code == 201 else None
upload_id = json_data['id']


#########################
# Assert against errors #
#########################

# check upload status
response = requests.get(f'https://api.mapbox.com/uploads/v1/devdatalab/{upload_id}', params=params)

# assert there are no errors
json_data = response.json() if response and response.status_code == 200 else None
error = json_data['error']
assert not error

