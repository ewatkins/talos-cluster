#!/usr/bin/env bash
set -Eeuo pipefail

# User-defined variables
PUSHOVER_ENABLED="${PUSHOVER_ENABLED:-false}"
PUSHOVER_USER_KEY="${PUSHOVER_USER_KEY:-required}"
PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-required}"

# Function to set release variables from SABnzbd
set_sab_vars() {
    RELEASE_NAME="${SAB_FILENAME:-}"
    RELEASE_DIR="${SAB_COMPLETE_DIR:-}"
    RELEASE_CAT="${SAB_CAT:-}"
    RELEASE_SIZE="${SAB_BYTES:-}"
    RELEASE_STATUS="${SAB_PP_STATUS:-}"
    RELEASE_INDEXER="${SAB_URL:-Unknown}"
    RELEASE_TYPE="NZB"
}

# Function to send pushover notification
send_pushover_notification() {
    local pushover_message status_code json_data
    printf -v pushover_message \
        "<b>%s</b><small>\n<b>Category:</b> %s</small><small>\n<b>Indexer:</b> %s</small><small>\n<b>Size:</b> %s</small>" \
            "${RELEASE_NAME%.*}" \
            "${RELEASE_CAT}" \
            "$(trurl --url "${RELEASE_INDEXER}" --get '{idn:host}')" \
            "$(numfmt --to iec --format "%8.2f" "${RELEASE_SIZE}")"

    json_data=$(jo \
        token="${PUSHOVER_TOKEN}" \
        user="${PUSHOVER_USER_KEY}" \
        title="${RELEASE_TYPE} Downloaded" \
        message="${pushover_message}" \
        priority="-2" \
        html="1"
    )

    status_code=$(curl \
        --silent \
        --write-out "%{http_code}" \
        --output /dev/null \
        --request POST  \
        --header "Content-Type: application/json" \
        --data-binary "${json_data}" \
        "https://api.pushover.net/1/messages.json"
    )

    printf "pushover notification returned with HTTP status code %s and payload: %s\n" \
        "${status_code}" \
        "$(echo "${json_data}" | jq --compact-output)" >&2
}

main() {
    # Determine the source app and set release variables accordingly
    case $HOSTNAME in
        sabnzbd*)
            set_sab_vars
            ;;
        *)
            printf "unknown hostname %s\n" "${HOSTNAME}" >&2
            exit 1
            ;;
    esac

    # Check if post-processing was successful
    if [[ "${RELEASE_STATUS}" -ne 0 ]]; then
        printf "post-processing failed with sabnzbd status code %s\n" \
            "${RELEASE_STATUS}" >&2
        exit 1
    fi

    # Update permissions on the release directory
    # chmod -R 750 "${RELEASE_DIR}"

    # Send pushover notification
    if [[ "${PUSHOVER_ENABLED}" == "true" ]]; then
        send_pushover_notification
    fi

}

main "$@"
