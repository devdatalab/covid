#!/usr/bin/env bash

# set this up with the following cron command (executes at 1030AM daily):
# $ crontab -e
# $ 30 10 * * * source $HOME/.bashrc; touch $TMP/rerun_indicator.txt; $HOME/ddl/covid/forecasting/update_forecasts_cronjob.sh

# depends on slack messaging hook in env variable SLACKKEY
if [[ -z "$SLACKKEY" ]]; then
  printf "\nENV variable $SLACKKEY must be defined for cronjob to execute. Add to your .bashrc\n"
fi

# send init message via slack
curl -X POST -H 'Content-type: application/json' --data '{"text":":building_construction: Beginning auto-update of COVID forecasting platform"}' https://hooks.slack.com/services/$SLACKKEY

# change dir to scratch for logging
cd /scratch/`whoami`

# run update script with basic error handling
printf "\nbegin update build: ~/ddl/covid/forecasting/Snakemake\n"
if snakemake --directory $HOME/ddl/covid/forecasting/ --snakefile $HOME/ddl/covid/forecasting/Snakefile --cores 4 --use-conda; then

  # if we don't have an error, send a slack
  curl -X POST -H 'Content-type: application/json' --data '{"text":":not-a-dumpster-fire: Successful update of forecasting data!"}' https://hooks.slack.com/services/$SLACKKEY
else

  # if we do have an error, send a slack
  curl -X POST -H 'Content-type: application/json' --data '{"text":":rotating_light: FAILURE: auto-update of COVID data had non-zero exit status"}' https://hooks.slack.com/services/$SLACKKEY
fi 

# move back to starting dir
cd -
