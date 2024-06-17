#!/bin/sh

cd $CI_PRIMARY_REPOSITORY_PATH/Utils || exit 1
printf "{\"authTestURL\":\"%s\",\"forumTestURL\":\"%s\",\"curriculumTestURL\":\"%s\"}" "$AUTH_TEST_URL" "$FORUM_TEST_URL" "$CURRICULUM_TEST_URL" > demo.json
