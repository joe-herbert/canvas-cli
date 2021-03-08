#!/bin/bash
set -e

#get/check canvas token
CANVAS_URL=""
CANVAS_TOKEN=""
SETTINGS_LOCATION=~/.config/canvas_settings
CHANGE_ENABLED=false
if [ "$1" = "-c" ]; then
    CHANGE_ENABLED=true
fi

get_canvas_token() {
    if [ -f $SETTINGS_LOCATION ]; then
        settings=$(cat "$SETTINGS_LOCATION")
        settingsArr=(${settings//|/ })
        CANVAS_URL="${settingsArr[0]}"
        CANVAS_TOKEN="${settingsArr[1]}"

        #change option enabled
        if [ "$CHANGE_ENABLED" = true ]; then
            read -p "Enter canvas url (e.g. liverpool.instructure.com): " tmpUrl
            if [ "$tmpUrl" != "" ]; then 
                CANVAS_URL="https://$tmpUrl"
            fi
            read -p "Enter canvas token: " tmpToken
            if [ "$tmpToken" != "" ]; then
                CANVAS_TOKEN="$tmpToken"
            fi
            if [ "$(check_canvas_token "$CANVAS_TOKEN")" = "200" ]; then
                rm -f $SETTINGS_LOCATION
                echo $(echo -ne "$CANVAS_URL|$CANVAS_TOKEN" > $SETTINGS_LOCATION)
                chmod 400 $SETTINGS_LOCATION
            else
                get_canvas_token
            fi
        fi
    else
        read -p "Enter canvas url (e.g. liverpool.instructure.com): " CANVAS_URL
        CANVAS_URL="https://$CANVAS_URL"
        read -p "Enter canvas token: " CANVAS_TOKEN
        echo $(echo -ne "$CANVAS_URL|$CANVAS_TOKEN" > $SETTINGS_LOCATION)
        chmod 400 $SETTINGS_LOCATION
    fi
}

check_canvas_token() {
    curl -so /dev/null -w "%{http_code}" -H "Authorization: Bearer $1" "$CANVAS_URL/api/v1/accounts"
}

get_canvas_token
check_status=$(check_canvas_token "$CANVAS_TOKEN")
while [ "$check_status" != "200" ]; do
    echo
    rm -f $SETTINGS_LOCATION
    get_canvas_token
    check_status=$(check_canvas_token "$CANVAS_TOKEN")
    echo $check_status
done
