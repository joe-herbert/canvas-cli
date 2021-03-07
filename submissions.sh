#!/bin/bash
. setup.sh
. loader.sh

for row in $(curl -s -H "Authorization: Bearer $CANVAS_TOKEN" "$CANVAS_URL/api/v1/users/self/activity_stream?per_page=99999999999" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    if [ "$(_jq '.type')" = "Submission" ]
    then
        echo $(_jq '.type') - $(_jq '.title')
    fi
done
