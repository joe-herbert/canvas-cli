#get/check canvas token
CANVAS_URL="https://liverpool.instructure.com"
CANVAS_TOKEN=""

get_canvas_token() {
    if [ -f ~/.config/canvas_settings ]; then
        unset -v CANVAS_URL CANVAS_TOKEN
        { IFS= read -r CANVAS_URL && IFS= read -r CANVAS_TOKEN; } < ~/.config/canvas_settings
    else
        read -p "Enter canvas url (e.g. liverpool.instructure.com): " CANVAS_URL
        CANVAS_URL="https://$CANVAS_URL"
        read -p "Enter canvas token: " CANVAS_TOKEN
        echo -ne "$CANVAS_URL\n$CANVAS_TOKEN" > ~/.config/canvas_settings
        chmod 400 ~/.config/canvas_settings
    fi
}

check_canvas_token() {
    curl -so /dev/null -w "%{http_code}" -H "Authorization: Bearer $1" "$CANVAS_URL/api/v1/accounts"
}

get_canvas_token
check_status=$(check_canvas_token "$CANVAS_TOKEN")
while [ "$check_status" != "200" ]; do
    echo
    rm -f ~/.config/canvas_settings
    get_canvas_token
    check_status=$(check_canvas_token "$CANVAS_TOKEN")
done
