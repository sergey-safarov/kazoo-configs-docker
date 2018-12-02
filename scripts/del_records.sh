#!/bin/sh

API_URI=http://kz-app1a.kazoo:8000/v2

MASTER_ACCOUNT_ID=xxxxxxx
API_KEY=xxxxxx
WORKING_DIRECTORY=/tmp
START_TIMESTAMP="2 month ago"
TIME_PERIOD="1 month"
RECORDS_MAX=50000

get_token() {
    local API_URI=$1
    local API_KEY=$2
    curl -s -S -X PUT $API_URI/api_auth -H "Content-Type: application/json" -d "{ \"data\" : { \"api_key\" : \"$API_KEY\" }}" | jq -j '.auth_token'
}

get_descendants() {
    local ACCOUNT_ID=$1
    curl -s -S -X GET "$API_URI/accounts/$ACCOUNT_ID/descendants?paginate=false" -H "X-Auth-Token: $TOKEN" | jq -j '[.data[].id] | join(" ")'
}

get_unix_timestamp_start() {
    date +%s --date="$START_TIMESTAMP"
}

get_unix_timestamp_stop() {
    date +%s --date="$START_TIMESTAMP $TIME_PERIOD"
}

get_gregorian_timestamp() {
    local UNIX_TIMESTAMP=$1
    local TIMESTAMP=$((UNIX_TIMESTAMP + 62167219200))
    echo $TIMESTAMP
}

get_account_recordings_list() {
    local ACCOUNT_ID=$1
    local TIMESTAMP=$(get_unix_timestamp_start)
    local TIMESTAMP_START=$(get_gregorian_timestamp $TIMESTAMP)
    local TIMESTAMP=$(get_unix_timestamp_stop)
    local TIMESTAMP_STOP=$(get_gregorian_timestamp $TIMESTAMP)
    curl -s -S -X GET "$API_URI/accounts/$ACCOUNT_ID/recordings?page_size=$RECORDS_MAX&created_from=$TIMESTAMP_START&created_to=$TIMESTAMP_STOP" -H "X-Auth-Token: $TOKEN" | jq -j "[.data[].id | [\"$ACCOUNT_ID/recordings/\",.] | join(\"\")] | join(\"\n\")"
}

del_record() {
    local RECORD_REF=$1
    curl -s -S -X DELETE "$API_URI/accounts/$RECORD_REF?should_soft_delete=false" -H "X-Auth-Token: $TOKEN" > /dev/null
}

preparation() {
    rm -f $WORKING_DIRECTORY/cdr_list.txt
}

set -e
preparation

TOKEN=$(get_token "$API_URI" "$API_KEY")
if [ -z "$TOKEN" -o "$TOKEN" == "undefined" ]; then
    echo "{error: \"Cannon get auth token!!!\"}"
    exit 1
fi

ANY_ID=$@
if [ -z "$ANY_ID" ]; then
    ANY_ID=$(get_descendants "$MASTER_ACCOUNT_ID")
    ANY_ID=$(echo "$MASTER_ACCOUNT_ID $ANY_ID")
fi

for i in $ANY_ID; do
    echo "Processing account $i"
    get_account_recordings_list $i >> $WORKING_DIRECTORY/cdr_list.txt
    echo >> $WORKING_DIRECTORY/cdr_list.txt
done

echo "Deleting call recordings. Please wait..."
sed -i -e '/^\s*$/d' $WORKING_DIRECTORY/cdr_list.txt
while IFS= read -r line; do
   del_record "$line"
done < $WORKING_DIRECTORY/cdr_list.txt

exit 0
