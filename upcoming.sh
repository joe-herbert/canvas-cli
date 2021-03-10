#!/bin/bash
set -e

compact=false
blankMode=false
onlyFavCourses=false
includeLocked=false
includeSubmitted=false
filterCourses=false
courseList=()

while getopts ":hcbflsm:" opt; do
    case $opt in
        h ) echo -e "\nUsage:\n\tcanvas u [option]\n\tcanvas upcoming [option]"
            echo -e "Options:\n\t-h,Display this help message.\n\t-c,Display the output in compact style.\n\t-b,Enable blank mode so the output doesn't use colours.\n\t-f,Display only favourited courses.\n\t-l,Display assignments which haven't yet unlocked.\n\t-s,Display submitted assignments.\n\t-m [code],Display only specific courses. Courses should be specified as 3 digit numeric codes separated by a comma." | column -t -s ','
            echo -e "\nCanvas Token:\nYou must generate a canvas token to use this script. On Canvas, go to your Account Settings and look under Approved Integrations. Create a new access token with the name \"Canvas CLI\" and with no expiration date. Copy the token value, run any Canvas CLI command and paste the token when requested."
            exit 0
            ;;
        c ) compact=true;;
        b ) blankMode=true;;
        f ) onlyFavCourses=true;;
        l ) includeLocked=true;;
        s ) includeSubmitted=true;;
        m ) case $OPTARG in
                : ) echo "Invalid Option: -m requires an argument" 1>&2
                    exit 1
                    ;;
                "" ) ;;
                * ) filterCourses=true
                    while IFS=',' read -ra courses; do
                        for i in "${courses[@]}"; do
                            if [ "$i" != "" ]; then
                                courseList+=( ${i:0:3} )
                            fi
                        done
                    done <<< $(echo "$OPTARG" | sed 's/[^0-9,]*//g')
                    if [ ${#courseList[@]} = "0" ]; then
                        echo "Invalid course(s) '$OPTARG': see -h for more info" 1>&2
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

. setup.sh

#define vars for assignments
RED='\033[0;91m'
GREEN='\033[0;92m'
ORANGE='\033[0;93m'
NC='\033[0m'
COURSE_URL="$CANVAS_URL/api/v1/courses"
if [ "$onlyFavCourses" = true ]; then
    COURSE_URL="$CANVAS_URL/api/v1/users/self/favorites/courses"
fi
today=$(date +"%s")
twoDays=$(date -d "+2days" +"%s")
oneWeek=$(date -d "+10days" +"%s")
colorsArray=()
titlesArray=()
deadlinesArray=()
coursesArray=()
unlocksAtArray=()

. loader.sh

#for each course
for course in $(curl -s -H "Authorization: Bearer $CANVAS_TOKEN" "$COURSE_URL" | jq -r '.[] | @base64'); do

    _jqCourse() {
        echo ${course} | base64 --decode | jq -r ${1}
    }

    course_code="$(_jqCourse '.course_code')"
    if [ "$filterCourses" = false ] || [[ " ${courseList[@]} " =~ " ${course_code:4:3} " ]]; then
    
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
                        if [ $lock_at != "null" ] && [ $(date -d $lock_at +"%s") -le $deadline ]; then
                            deadline=$(date -d $lock_at +"%s")
                        fi
                        color=${NC}
                        if [ $(_jqRow '.submission' | jq -r '.workflow_state') != "unsubmitted" ]; then
                            if [ "$includeSubmitted" = false ]; then
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
                        coursesArray+=( ${course_code:4:3} )
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
    tableHeaders="Course,Title,Deadline"
    if [ "$includeLocked" = true ]; then
        tableHeaders="$tableHeaders,Unlocks At"
    fi
fi
lastCourse=""
printf "\033[1;2m"
for ((i=0; i<${#titlesArray[@]}; i++)); do
    if [ "$lastCourse" != "${coursesArray[i]}" ]; then
        if [ "$lastCourse" != "" ]; then
            echo -e "||"
        fi
        if [ "$compact" = false ]; then
            echo -e "\033[1;2m${coursesArray[i]}"
            fi
            lastCourse=${coursesArray[i]}
        fi
    line="${titlesArray[i]}${NC}|${deadlinesArray[i]}"
    if [ "$blankMode" = false ]; then
        line="${colorsArray[i]}$line"
    fi
    if [ "$compact" = true ]; then
        line="${NC}${coursesArray[i]}|$line"
    fi
    if [ "$includeLocked" = true ]; then
        line="$line|${unlocksAtArray[i]}"
    fi
    echo -e "$line"
done | column -t -s '|' -N "$tableHeaders"
