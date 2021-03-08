#!/bin/bash

#while getopts ":h" opt; do
#    case ${opt} in
#        h ) 
#            echo_help
#            exit 0
#            ;;
#        \? )
#            echo "Invalid Option: -$OPTARG" 1>&2
#            exit 1
#            ;;
#    esac
#done
#shift $((OPTIND -1))

subcommand=$1; shift  # Remove 'pip' from the argument list
case "$subcommand" in
    # Parse options to the install sub command
    h|help|""|"-h"|"--help" )
        echo
        echo -e "Usage:\n\tcanvas <operation> -h,Display help for specific operation.\n\tcanvas <operation> [option],Execute one of the operations below." | column -t -s ','
        echo -e "Operations:\n\th help,Display this help message.\n\tu upcoming,Display any assignments which are due in the future.\n\tg grades,Display submitted assignments and grades.\n\ts settings,Change your canvas url or token." | column -t -s ','
        echo -e "\nCanvas Token:\nYou must generate a canvas token to use this script. On Canvas, go to your Account Settings and look under Approved Integrations. Create a new access token with the name \"Canvas CLI\" and with no expiration date. Copy the token value, run any Canvas CLI command and paste the token when requested."
        exit 0
        ;;
    u|upcoming )
        . upcoming.sh
        ;;
    g|grades )
        . grades.sh
        ;;
    s|settings )
        . setup.sh -c
        ;;
    * )
        echo "Canvas CLI: Unknown command. See canvas -h for help."
        exit 0
        ;;
esac
