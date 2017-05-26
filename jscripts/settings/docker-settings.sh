#!/usr/bin/env bash

[[ -n "${_DOCKER_SETTINGS_SH:+_}" ]] && return || readonly _DOCKER_SETTINGS_SH=1

source ${SCRIPT_DIR}/settings/common.sh

##
# Environment variables that control how images are named/deployed/built etc.
##
: ${LOCAL_IMAGE_VERSION_TAG:='current'}
: ${DOCKER_REGISTRY_URL:=''}
: ${DOCKER_REGISTRY_ORG:='jnorwood'}
: ${ADDITIONAL_DOCKER_BUILD_ARGS:=''}
: ${ADDITIONAL_DOCKER_PUSH_ARGS:=''}
: ${DOCKER_PUSH_KEEP_TAGGED:='false'}


##
# List here all of the images built/deployed/used by the project
##
readonly NGINX_IMAGE_NAME='nginx'
readonly SERVER_CODE_IMAGE_NAME='server_code'
readonly SERVER_TESTS_IMAGE_NAME='server_tests'
readonly UWSGI_IMAGE_NAME='uwsgi'

readonly RPI_NGINX_IMAGE_NAME='rpi_nginx'
readonly RPI_SERVER_CODE_IMAGE_NAME='rpi_server_code'
readonly RPI_UWSGI_IMAGE_NAME='rpi_uwsgi'


readonly _DOCKER_CONFIG=$(cat <<EOF
{
    "buildImages": [
        "${NGINX_IMAGE_NAME}",
        "${UWSGI_IMAGE_NAME}"
    ],
    "deployImages": [
        "${NGINX_IMAGE_NAME}",
        "${UWSGI_IMAGE_NAME}"
    ],
    "imageDependencies": {}
}
EOF
)

function print_build_images_usage_list {
    echo -n "  "
    join "\n  " $(get_images_to_build)
    echo
}

function print_deploy_images_usage_list {
    echo "  $(join "\n  " `get_images_to_deploy`)"
}

##
# Settings for which images should be built/deployed by these scripts, as well as how to build and deploy them
##
function get_images_to_build {
    jq -r ".buildImages[]" <<< "${_DOCKER_CONFIG}"
}

function get_images_to_deploy {
    jq -r ".deployImages[]" <<< "${_DOCKER_CONFIG}"
}

function get_image_dependencies_for_image {
    local image=${1}
    jq -r ".imageDependencies.${image} | if . == null then \"\" else .[] end" <<< "${_DOCKER_CONFIG}"
}

function get_image_name {
    local image=${1}
    echo "${PROJECT_NAME}-${image}"
}

function get_dockerfile_path_for_image {
    local image=${1}
    echo "docker/Dockerfile-${image}"
}

function get_docker_build_context_path_for_image {
    local image=${1}
    echo "."
}

function get_image_version {
    local image=${1}
    cat "versions/${image}.txt"
}

function get_docker_registry_name {
    if [[ -z "${DOCKER_REGISTRY_URL:+_}" ]]; then
        echo "DockerHub"
    else
        echo "${DOCKER_REGISTRY_URL:+_}"
    fi
}

##
# Hooks around building and deploying images
##
function pre_build_image_hook {
    local image=${1}
    log_debug "Pre Build Image Hook for image '${image}'"
}

function post_build_image_hook {
    local image=${1}
    log_debug "Post Build Image Hook for image '${image}'"
}

function pre_deploy_image_hook {
    local image=${1}
    log_debug "Pre Deploy Image Hook for image '${image}'"
}

function post_deploy_image_hook {
    local image=${1}
    log_debug "Post Deploy Image Hook for image '${image}'"
}
