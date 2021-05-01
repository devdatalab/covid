#!/usr/bin/env bash

# NOTE: this is currently set up so only Toby can run it
# this could be changed once we get an all-user dropbox acct set up for Rclone, and
# have all users set an ENV variable that includes their slack key

# Toby has set this up with the following cron command (execute just after midnight daily):
# $ crontab -l
# $ 5 5 * * * $HOME/ddl/covid/b/update_case_cronjob.sh

# set local variable with slack key
slackkey='T4FD3N0E6/B01D1MT6LL8/u0LramgqZEpjhGCV8wNqOgDA'

# send init message via slack
curl -X POST -H 'Content-type: application/json' --data '{"text":":building_construction: Beginning auto-update of COVID case and vaccination data"}' https://hooks.slack.com/services/$slackkey

# change dir to scratch for logging
cd /scratch/`whoami`

# run update script
printf "\nbegin update script: ~/ddl/covid/b/update_case_vaccination_data.do\n"
stata -b do ~/ddl/covid/b/update_case_vaccination_data.do

# check log for errors
printf "\nchecking Stata log for errors...\n"
if egrep --before-context=1 --max-count=1 "^r\([0-9]+\);$" "update_case_vaccination_data.log"
then
  # send error message
  printf "\nFAIL - you have a data dumpster fire on your hands!"
  curl -X POST -H 'Content-type: application/json' --data '{"text":":rotating_light: FAILURE: auto-update of COVID data had non-zero exit status"}' https://hooks.slack.com/services/$slackkey
  exit 1
else
  # send success message
  curl -X POST -H 'Content-type: application/json' --data '{"text":":not-a-dumpster-fire: Successful update of COVID data!"}' https://hooks.slack.com/services/$slackkey
  printf "\nSuccess!"
  exit 0
fi

# move back to starting dir
cd -
