# pulls complete predictions data from Satej's google cloud bucket
from google.cloud import storage
from pathlib import Path 
import argparse

# initialize args
parser = argparse.ArgumentParser()
parser.add_argument("--dir", type=str)
args = parser.parse_args()

# set target location
target_path = Path(f'{args.dir}')

# define name of satej's GC bucket
bucket_name = "daily_pipeline"

# loop over estimates and download each file
for blob in storage.Client().list_blobs(bucket_name, prefix = "pipeline/est"):
    filename = Path(blob.name).name
    print(f"{blob.name} -> {filename}")
    blob.download_to_filename(target_path / filename)
