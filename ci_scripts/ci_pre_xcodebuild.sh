#!/bin/sh

cd $CI_PRIMARY_REPOSITORY_PATH/Utils || exit 1
printf "{\"auth_url\":\"%s\",\"forum_url\":\"%s\",\"curriculum_url\":\"%s\"}" "$AUTH_URL" "$FORUM_URL" "$CURRICULUM_URL" > secrets.json
