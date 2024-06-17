#!/bin/sh

cd $CI_PRIMARY_REPOSITORY_PATH/Utils || exit 1
printf "{\"authTestURL\":\"%s\",\"forumTestURL\":\"%s\",\"curriculumTestURL\":\"%s\"}" "$AUTH_URL" "$FORUM_URL" "$CURRICULUM_URL" > demo.json
