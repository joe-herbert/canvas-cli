#!/bin/bash
set -e

#help plans
#explain how to get canvas token
#-c compact output - original one table style
#-a any - not just assignments which are available right now
#-m specify module
#-s include submitted

compact=false
includeLocked=false
includeSubmitted=false
filterModules=false
moduleList=()

while getopts ":hclsm:" opt; do
    case $opt in
        h ) echo -e "Usage:\n\t-h,Display this help message.\n\t-c,Display the output in compact style.\n\t-l,Display assignments which haven't yet unlocked.\n\t-s,Display submitted assignments.\n\t-m [code],Display only specific modules. Modules should be specified as 3 digit numeric codes separated by a comma." | column -t -s ','
            echo -e "\nCanvas Token:\nYou must generate a canvas token to use this script. On Canvas, go to your Account Settings and look under Approved Integrations. Create a new access token with the name \"Canvas CLI\" and with no expiration date. Copy the token value, run any Canvas CLI command and paste the token when requested."
            exit 0
            ;;
        c ) compact=true;;
        l ) includeLocked=true;;
        s ) includeSubmitted=true;;
        m ) case $OPTARG in
                : ) echo "Invalid Option: -m requires an argument" 1>&2
                    exit 1
                    ;;
                "" ) ;;
                * ) filterModules=true
                    while IFS=',' read -ra modules; do
                        for i in "${modules[@]}"; do
                            if [ "$i" != "" ]; then
                                moduleList+=( ${i:0:3} )
                            fi
                        done
                    done <<< $(echo "$OPTARG" | sed 's/[^0-9,]*//g')
                    if [ ${#moduleList[@]} = "0" ]; then
                        echo "Invalid module(s) '$OPTARG': see -h for more info" 1>&2
                        exit 1
                    fi
                    ;;
            esac
            ;;
        \? ) echo "Invalid Option: -$OPTARG" 1>&2
             exit 1
             ;;
    esac
done

echo "before set up"
. setup.sh

echo "set up complete"

#define vars for assignments
RED='\033[0;91m'
GREEN='\033[0;92m'
ORANGE='\033[0;93m'
NC='\033[0m'
today=$(date +"%s")
twoDays=$(date -d "+2days" +"%s")
oneWeek=$(date -d "+10days" +"%s")
colorsArray=()
titlesArray=()
deadlinesArray=()
modulesArray=()
unlocksAtArray=()

. loader.sh

#for each course
for course in $(curl -s -H "Authorization: Bearer $CANVAS_TOKEN" "$CANVAS_URL/api/v1/courses" | jq -r '.[] | @base64'); do

    _jqCourse() {
        echo ${course} | base64 --decode | jq -r ${1}
    }

    course_code="$(_jqCourse '.course_code')"
    if [ "$filterModules" = false ] || [[ " ${moduleList[@]} " =~ " ${course_code:4:3} " ]]; then
    
        for row in $(curl -s -H "Authorization: Bearer $CANVAS_TOKEN" "$CANVAS_URL/api/v1/courses/$(_jqCourse '.id')/assignments?order_by=due_at&include[]=submission" | jq -r '.[] | @base64'); do

            _jqRow() {
                echo ${row} | base64 --decode | jq -r ${1}
            }

            unlock_at=$(_jqRow '.unlock_at')
            due_at=$(_jqRow '.due_at')
            lock_at=$(_jqRow '.lock_at')

            #need to check if unlock_at is null or in the past
            if [ "$includeLocked" = true ] || [ "$unlock_at" = "null" ] || [ "$(date -d $unlock_at +"%s")" -le $today ]; then
                #need to check if due_at is in the future
                if [ "$due_at" != "null" ] && [ "$(date -d $due_at +"%s")" -ge $today ]; then
                    #need to check if lock_at is null or in the future
                    if [ "$lock_at" = "null" ] || [ "$(date -d $lock_at +"%s")" -ge $today ]; then
                        deadline=$(date -d $due_at +"%s")
                        if [ $lock_at != "null" ]; then
                            deadline=$(date -d $lock_at +"%s")
                        fi
                        color=${NC}
                        if [ $(_jqRow '.submission' | jq -r '.workflow_state') != "unsubmitted" ]; then
                            if [ "$includeSubmitted"=false ]; then
                                continue
                            fi
                            color=${GREEN}
                        elif [ "$deadline" -le "$twoDays" ]; then
                            color=${RED}
                        elif [ "$deadline" -le "$oneWeek" ]; then
                            color=${ORANGE}
                        fi
                        colorsArray+=( "$color" )
                        titlesArray+=( "$(_jqRow '.name')" )
                        deadlinesArray+=( "$(date -d $due_at +"%a %d %b %Y %H:%M")" )
                        modulesArray+=( ${course_code:4:3} )
                        if [ "$includeLocked" = true ]; then
                            if [ "$unlock_at" = "null" ] || [ "$(date -d $unlock_at +"%s")" -le $today ]; then
                                unlocksAtArray+=( "" )
                            else
                                unlocksAtArray+=( "$(date -d $unlock_at +"%a %d %b %Y %H:%M")" )
                            fi
                        fi
                    fi
                fi
            fi


        done
    fi
done

#output
tableHeaders=""
if [ "$compact" = true ]; then
    tableHeaders="Module,Title,Deadline"
    if [ "$includeLocked" = true ]; then
        tableHeaders="$tableHeaders,Unlocks At"
    fi
fi
lastModule=""
printf "\033[1;2m"
for ((i=0; i<${#titlesArray[@]}; i++)); do
    if [ "$lastModule" != "${modulesArray[i]}" ]; then
        if [ "$lastModule" != "" ]; then
            echo -e ",,"
        fi
        if [ "$compact" = false ]; then
            echo -e "\033[1;2m${modulesArray[i]}"
        fi
        lastModule=${modulesArray[i]}
    fi
    line="${colorsArray[i]}${titlesArray[i]}${NC},${deadlinesArray[i]}"
    if [ "$compact" = true ]; then
        line="${NC}${modulesArray[i]},$line"
    fi
    if [ "$includeLocked" = true ]; then
        line="$line,${unlocksAtArray[i]}"
    fi
    echo -e "$line"
done | column -t -s ',' -N "$tableHeaders"
