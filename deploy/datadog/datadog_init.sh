#!/bin/bash
#
# Description: Script for managment helm chart
# Maintainer: edmilson.alferes <edmilson.alferes@gmail.com>

# Global Variables
LOG_FILE="datadog_init.log"
DATADOG_API_KEY=""

# Use log info <function> <msg>
log_info(){

	TEXT_COLOR_INIT="\e[0;32m"
    TEXT_COLOR_FINAL="\e[0m"
	DT=$(date "+%Y/%m/%d %H:%M:%S")
	STR_CONSOLE="${TEXT_COLOR_INIT} [${DT}] - [INFO] - [${1}]: ${2} ${TEXT_COLOR_FINAL}"
    STR_FILE="[${DT}] - [INFO] - [${1}]: ${2}"
    echo -e ${STR_CONSOLE}
    echo ${STR_FILE} >> ${LOG_FILE}
}

# Use log warning <function> <msg>
log_warning(){

	TEXT_COLOR_INIT="\e[1;33m"
    TEXT_COLOR_FINAL="\e[0m"
	DT=$(date "+%Y/%m/%d %H:%M:%S")
	STR_CONSOLE="${TEXT_COLOR_INIT} [${DT}] - [INFO] - [${1}]: ${2} ${TEXT_COLOR_FINAL}"
    STR_FILE="[${DT}] - [INFO] - [${1}]: ${2}"
    echo -e ${STR_CONSOLE}
    echo ${STR_FILE} >> ${LOG_FILE}
}

# Use log error <function> <msg>
log_error(){

	TEXT_COLOR_INIT="\e[1;31m"
    TEXT_COLOR_FINAL="\e[0m"
	DT=$(date "+%Y/%m/%d %H:%M:%S")
	STR_CONSOLE="${TEXT_COLOR_INIT} [${DT}] - [INFO] - [${1}]: ${2} ${TEXT_COLOR_FINAL}"
    STR_FILE="[${DT}] - [INFO] - [${1}]: ${2}"
    echo -e ${STR_CONSOLE}
    echo ${STR_FILE} >> ${LOG_FILE}
}

info_header(){
    echo ""
    echo  "Script: init.sh"
    echo  "Maintainer: edmilson.alferes <edmilson.alferes@gmail.com>"
    echo  "Description: Script for managment ${CHART}"
}

help_info() {

    info_header
    
    echo ""
    echo " Use option to script: " 
    echo ""
    echo " --install                 - Install helm ${CHART}"
    echo " --delete                  - Delete helm ${CHART}"
    echo " --help | -h               - Show this info."
    echo ""
}

# Update chart
add_update() {

    helm repo add datadog https://helm.datadoghq.com
    helm repo update
}

# Install chart
install() {
	# Install datadog (APM ONLY)
	helm upgrade --install datadog datadog/datadog \
	    -n datadog \
	    --create-namespace \
	    --set datadog.apiKey=${DATADOG_API_KEY} \
	    --set datadog.clusterName=k8s-developer-${HOSTNAME,,} \
	    --set datadog.apm.portEnabled=true \
	    --set datadog.apm.socketEnabled=true \
	    --set datadog.tags[0].env=developer \
	    --set datadog.logs.enabled=false \
	    --set clusterAgent.enabled=true \
	    --set clusterAgent.admissionController.enabled=true \
	    --set clusterAgent.admissionController.mutateUnlabelled=true
}

# Delete chart
delete() {
	helm delete datadog -n datadog
}


main() {

    local OPTION=${1}

    case ${OPTION} in
        --install)
            add_update
            install
        ;;
        --delete)
            delete
        ;;
        --help | -h)
            help_info
        ;;
        *) log_error "main" "Invalid option: ${OPTION}" 
            help_info
        ;;
    esac

}

main $@