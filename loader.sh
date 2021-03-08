#loader
set -e

loader() {
    str="Loading"
    echo -ne "$str\r"
    while true; do
        str="$str."
        if [ $str = "Loading....." ]; then
            echo -ne "           \r"
            str="Loading"
        fi
        echo -ne "$str\r"
        sleep .5
    done
}

loader &
LOADER_PID=$!
trap "kill -9 $LOADER_PID" `seq 0 15`
