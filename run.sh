#!/bin/bash

gpg --import /keys/*

cron

# LS_COLORS is set to nothing and for some strange reason crontabs are not allowed to contain such env vars
unset LS_COLORS

# Create crontab file
env | cat - > /backup.cron
echo "$CRON_INTERVAL /backup.sh" >> /backup.cron

crontab /backup.cron

tail -f /dev/null
