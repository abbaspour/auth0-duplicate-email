#!/bin/bash

# create a user in unique
# create a user in fixer
# link them

set -eo pipefail

declare -r db_BE='unique'
declare -r db_FE='fixer'

declare -r AUTH0_DOMAIN='AAA.BB.auth0.com'
declare -r AUTH0_CLIENT_ID='CCCC'
declare -r AUTH0_CLIENT_SECRET='XXXXX'

declare -r AUTH0_DOMAIN_URL="https://$AUTH0_DOMAIN"
declare -r AUTH0_AUDIENCE="${AUTH0_DOMAIN_URL}/api/v2/"

function usage() {
    cat <<END >&2
USAGE: $0 [-e env] [-u username] [-p password] [-m mail] [-v|-h]
        -e file     # .env file location (default cwd)
        -a token    # access_token. default from environment variable
        -u username # username
        -m email    # email
        -p password # password
        -h|?        # usage
        -v          # verbose

eg,
     $0 -u user01 -m a.abbaspour@gmail.com -p ramzvorood
END
    exit $1
}

function get_access_token() {
    declare BODY=$(cat <<EOL
{
    "client_id":"${AUTH0_CLIENT_ID}",
    "client_secret":"${AUTH0_CLIENT_SECRET}",
    "audience":"${AUTH0_AUDIENCE}",
    "grant_type":"client_credentials"
}
EOL
    )
    local access_token=$(curl -s --header 'content-type: application/json' -d "${BODY}" ${AUTH0_DOMAIN_URL}/oauth/token | jq -r '.access_token')
    echo ${access_token}
}

function randomId() {
    for i in {0..20}; do
        echo -n $(( RANDOM % 10 ))
    done
}

function create_user() {
    local db=$1
    local user_id=$2
    local username=$3
    local password=$4
    local email=$5
    local real_email=$6

    local app_metadata_field=''
    [[ -n "${real_email}" ]] && app_metadata_field="\"app_metadata\": {\"real_email\" : \"${real_email}\"},"

    local password_field=''
    [[ -n "${password}" ]] && password_field="\"password\": \"${password}\","

    declare BODY=$(cat <<EOL
{
      "connection": "${db}",
      "user_id": "${user_id}",
      "username" : "${username}",
      ${app_metadata_field}
      ${password_field}
      "email" : "${email}"
}
EOL
    )

    curl --request POST \
        -H "Authorization: Bearer ${access_token}" \
        --url ${AUTH0_DOMAIN_URL}/api/v2/users \
        --header 'content-type: application/json' \
        --data "${BODY}"

}

while getopts "e:a:u:m:p:hv?" opt
do
    case ${opt} in
        e) source ${OPTARG};;
        a) access_token=${OPTARG};;
        u) username=${OPTARG};;
        m) email=${OPTARG};;
        p) password=${OPTARG};;
        v) opt_verbose=1;; #set -x;;
        h|?) usage 0;;
        *) usage 1;;
    esac
done


declare -r access_token=$(get_access_token)
#echo $access_token
#[[ -z ${access_token+x} ]] && { echo >&2 "ERROR: no 'access_token' defined. export access_token=\`pbpaste\`"; exit 1; }
#declare -r AUTH0_DOMAIN_URL=$(echo ${access_token} | awk -F. '{print $2}' | base64 -di 2>/dev/null | jq -r '.iss')

[[ -z ${username} ]] && { echo >&2 "ERROR: username undefined"; usage 1; }
[[ -z ${password} ]] && { echo >&2 "ERROR: password undefined"; usage 1; }
[[ -z ${email} ]] && { echo >&2 "ERROR: email undefined"; usage 1; }

declare user_id=$(randomId)
declare be_user_id="${user_id}"

echo "creating user in BE: ${be_user_id} / ${username} / ${username}+${email}"
create_user ${db_BE} ${be_user_id} ${username} ${password} "${username}+${email}" ${email}
