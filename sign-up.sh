#!/bin/bash

set -eo pipefail

declare -r DIR=$(dirname ${BASH_SOURCE[0]})
[[ -f ${DIR}/.env ]] && . ${DIR}/.env

function usage() {
    cat <<END >&2
USAGE: $0 [-e env] [-t tenant] [-c client_id] [-x client_secret] [-u username] [-p password] [-m mail] [-d database] [-v|-h]
        -e file         # .env file location (default cwd)
        -c client_id    # Auth0 client ID
        -x secret       # Auth0 client secret
        -u username     # username
        -m email        # email
        -p password     # password
        -d database     # backend database connection name
        -h|?            # usage
        -v              # verbose

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

function create_user() {
    local db=$1
    local username=$2
    local password=$3
    local real_email=$4

    local email="${username}+${email}"

    declare BODY=$(cat <<EOL
{
      "connection": "${db}",
      "username" : "${username}",
      "app_metadata": {"real_email" : "${real_email}"},
      "password": "${password}",
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

while getopts "e:r:c:x:d:u:m:p:hv?" opt
do
    case ${opt} in
        e) source ${OPTARG};;
        t) AUTH0_DOMAIN=`echo ${OPTARG}.auth0.com | tr '@' '.'`;;
        c) AUTH0_CLIENT_ID=${OPTARG};;
        x) AUTH0_CLIENT_SECRET=${OPTARG};;
        d) AUTH0_CONNECTION=${OPTARG};;
        u) username=${OPTARG};;
        m) email=${OPTARG};;
        p) password=${OPTARG};;
        v) opt_verbose=1;; #set -x;;
        h|?) usage 0;;
        *) usage 1;;
    esac
done


[[ -z ${AUTH0_DOMAIN} ]] && { echo >&2 "ERROR: AUTH0_DOMAIN undefined"; usage 1; }
[[ -z ${AUTH0_CLIENT_ID} ]] && { echo >&2 "ERROR: AUTH0_CLIENT_ID undefined"; usage 1; }
[[ -z ${AUTH0_CLIENT_SECRET} ]] && { echo >&2 "ERROR: AUTH0_CLIENT_SECRET undefined"; usage 1; }
[[ -z ${AUTH0_CONNECTION} ]] && { echo >&2 "ERROR: AUTH0_CONNECTION undefined"; usage 1; }

declare -r AUTH0_DOMAIN_URL="https://$AUTH0_DOMAIN"
declare -r AUTH0_AUDIENCE="${AUTH0_DOMAIN_URL}/api/v2/"

declare -r access_token=$(get_access_token)
#echo $access_token
#[[ -z ${access_token+x} ]] && { echo >&2 "ERROR: no 'access_token' defined. export access_token=\`pbpaste\`"; exit 1; }
#declare -r AUTH0_DOMAIN_URL=$(echo ${access_token} | awk -F. '{print $2}' | base64 -di 2>/dev/null | jq -r '.iss')

[[ -z ${username} ]] && { echo >&2 "ERROR: username undefined"; usage 1; }
[[ -z ${password} ]] && { echo >&2 "ERROR: password undefined"; usage 1; }
[[ -z ${email} ]] && { echo >&2 "ERROR: email undefined"; usage 1; }

echo "creating user in ${AUTH0_CONNECTION} database: ${username} / ${username}+${email}"
create_user ${AUTH0_CONNECTION} ${username} ${password} ${email}
