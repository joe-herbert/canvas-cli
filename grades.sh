#!/bin/bash
set -e

#help plans
#explain how to get canvas token
#-c compact output - original one table style
#-a any - not just assignments which are available right now
#-m specify course
#-s include submitted

compact=false
blankMode=false
onlyFavCourses=false
filterCourses=false
courseList=()

while getopts ":hcbfm:" opt; do
    case $opt in
        h ) echo -e "Usage:\n\t-h,Display this help message.\n\t-c,Display the output in compact style.\n\t-b,Enable blank mode so the output doesn't use colours.\n\t-f,Display only favourited courses.\n\t-m [code],Display only specific courses. Courses should be specified as 3 digit numeric codes separated by a comma." | column -t -s ','
            echo -e "\nCanvas Token:\nYou must generate a canvas token to use this script. On Canvas, go to your Account Settings and look under Approved Integrations. Create a new access token with the name \"Canvas CLI\" and with no expiration date. Copy the token value, run any Canvas CLI command and paste the token when requested."
            exit 0
            ;;
        c ) compact=true;;
        b ) blankMode=true;;
        f ) onlyFavCourses=true;;
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
today=$(date +"%s")
twoDays=$(date -d "+2days" +"%s")
oneWeek=$(date -d "+10days" +"%s")
colorsArray=()
titlesArray=()
coursesArray=()
scoresArray=()
outOfArray=()
COURSE_URL="$CANVAS_URL/api/v1/courses"
if [ "$onlyFavCourses" = true ]; then
    COURSE_URL="$CANVAS_URL/api/v1/users/self/favorites/courses"
fi

. loader.sh

#for each course
for course in $(curl -s -H "Authorization: Bearer $CANVAS_TOKEN" "$COURSE_URL" | jq -r '.[] | @base64'); do

    _jqCourse() {
        echo ${course} | base64 --decode | jq -r ${1}
    }

    course_code="$(_jqCourse '.course_code')"
    if [ "$filterCourses" = false ] || [[ " ${courseList[@]} " =~ " ${course_code:4:3} " ]]; then
    
        for row in $(curl -s -H "Authorization: Bearer $CANVAS_TOKEN" "$CANVAS_URL/api/v1/courses/$(_jqCourse '.id')/students/submissions?order=graded_at&include[]=assignment" | jq -r '.[] | @base64'); do

            _jqRow() {
                echo ${row} | base64 --decode | jq -r ${1}
            }

            if [ $(_jqRow '.workflow_state') != "unsubmitted" ]; then
                colorsArray+=( "$color" )
                titlesArray+=( "$(_jqRow '.assignment' | jq -r '.name')" )
                coursesArray+=( ${course_code:4:3} )
                score="$(_jqRow '.score')"
                if [ "$score" = "null" ] || [ "$score" = "0" ]; then
                    score="-"
                fi
                scoresArray+=( "$score" )
                outOf="$(_jqRow '.assignment' | jq -r '.points_possible')"
                if [ "$outOf" = "null" ] || [ "$outOf" = "0" ]; then
                    outOf="-"
                fi
                outOfArray+=( "$outOf" )
            fi
        done
    fi
done

#output
tableHeaders=""
if [ "$compact" = true ]; then
    tableHeaders="Course,Title,Score,Out Of,Grade"
fi
lastCourse=""
printf "\033[1;2m"
for ((i=0; i<${#titlesArray[@]}; i++)); do
    if [ "$lastCourse" != "${coursesArray[i]}" ]; then
        if [ "$lastCourse" != "" ]; then
            echo -e "|||"
        fi
        if [ "$compact" = false ]; then
            echo -e "\033[1;2m${coursesArray[i]}${NC}"
        fi
        lastCourse=${coursesArray[i]}
    fi
    color=$NC
    if [ "${outOfArray[i]}" = "-" ]; then
        grade="-"
    else
        grade="$(((scoresArray[i] * 100) / outOfArray[i]))"
        if [ "$blankMode" = false ]; then
            if [ "$grade" -eq "100" ]; then
                color=$GREEN
            elif [ "$grade" -ge "80" ]; then
                color=$ORANGE
            elif [ "$grade" -le "40" ]; then
                color=$RED
            fi
        fi
        grade="$grade%"
    fi
    line="$color${titlesArray[i]}$NC|${scoresArray[i]}|${outOfArray[i]}|$grade"
    if [ "$compact" = true ]; then
        line="${NC}${coursesArray[i]}|$line"
    fi
    echo -e "$line"
done | column -t -s '|' -N "$tableHeaders"
