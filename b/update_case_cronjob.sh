#!/usr/bin/env bash

# set this up with the following cron command (executes just after midnight daily):
# $ crontab -l
# $ 5 5 * * * $HOME/ddl/covid/b/update_case_cronjob.sh

# depends on slack messaging hook in env variable SLACKKEY
if [[ -z "$SLACKKEY" ]]; then
  printf "\nENV variable $SLACKKEY must be defined for cronjob to execute. Add to your .bashrc\n"
fi

# send init message via slack
curl -X POST -H 'Content-type: application/json' --data '{"text":":building_construction: Beginning auto-update of COVID case and vaccination data"}' https://hooks.slack.com/services/$SLACKKEY

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
  curl -X POST -H 'Content-type: application/json' --data '{"text":":rotating_light: FAILURE: auto-update of COVID data had non-zero exit status"}' https://hooks.slack.com/services/$SLACKKEY
  exit 1
else
  # send success message
  curl -X POST -H 'Content-type: application/json' --data '{"text":":not-a-dumpster-fire: Successful update of COVID data!"}' https://hooks.slack.com/services/$SLACKKEY
  printf "\nSuccess!"
  exit 0
fi

# move back to starting dir
cd -
