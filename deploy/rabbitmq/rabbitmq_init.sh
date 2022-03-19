#!/bin/bash
#
# Description: Script for managment helm chart
# Maintainer: edmilson.alferes <edmilson.alferes@gmail.com>

# Global Variables
LOG_FILE="rabbitmq_init.log"
KIND_INGRESS_ADDRESS=$(cat ../../ingress_address.txt)

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

  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
}

# Install chart
install() {

  helm upgrade --install rabbitmq bitnami/rabbitmq \
    -n rabbitmq \
    --create-namespace \
    -f rabbitmq.yaml \
    --set "ingress.hostname=rabbitmq.$KIND_INGRESS_ADDRESS" 

  log_info "install" "access deploy rabbitmq: http://rabbitmq.$KIND_INGRESS_ADDRESS"
}

# Delete chart
delete() {
	helm delete rabbitmq -n rabbitmq
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