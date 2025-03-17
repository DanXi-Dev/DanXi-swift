#!/bin/sh

export XCODE_PROJ_FILE=$CI_PRIMARY_REPOSITORY_PATH/DanXi.xcodeproj/project.pbxproj
python3 update_xcode_project.py || exit 1

cd $CI_PRIMARY_REPOSITORY_PATH/FudanUI || exit 1
rm -rf Preview/*

cd $CI_PRIMARY_REPOSITORY_PATH/DanXiUI || exit 1
rm -rf Preview/*

cd $CI_PRIMARY_REPOSITORY_PATH/Utils || exit 1
printf "{\"authTestURL\":\"%s\",\"forumTestURL\":\"%s\",\"curriculumTestURL\":\"%s\"}" "$AUTH_TEST_URL" "$FORUM_TEST_URL" "$CURRICULUM_TEST_URL" > demo.json
