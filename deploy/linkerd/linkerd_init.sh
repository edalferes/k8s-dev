#!/bin/bash
#
# Description: Script for managment linkerd 
# Maintainer: edmilson.alferes <edmilson.alferes@gmail.com>

# Global Variables
LOG_FILE="linkerd_init.log"
REPOSITORY_NAME="linkerd"
REPOSITORY_URI="https://helm.linkerd.io/stable"
REPOSITORY_FLAGGER="https://flagger.app"
YAML_LINKERD="linkerd.yaml"
YAML_LINKERD_VIZ="linkerd-viz.yaml"
LINKERD_VERSION_CHART="2.11.1"
FLAGGER_VERSION_CHART="1.14.0"


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
  echo  "Description: Script for managment linkerd"
}

help_info() {

  info_header
    
  echo ""
  echo " Use option to script: " 
  echo ""
  echo " --install                 - Install / upgrade  helm linkerd"
  echo " --delete                  - Delete helm linkerd"
  echo " --help | -h               - Show this info."
  echo ""
}

# Update chart linkerd and flagger
add_update() {

  helm repo add ${REPOSITORY_NAME} ${REPOSITORY_URI}
  helm repo add flagger ${REPOSITORY_FLAGGER}
  helm repo update
}

# Install/upgrade otimized control-plane
install_control_plane() {
    helm upgrade --install linkerd linkerd/linkerd2 \
      -f ${YAML_LINKERD} \
      --version ${LINKERD_VERSION_CHART} 
}

install_viz() {
  # Install/upgrade otimized viz
  helm upgrade --install linkerd-viz linkerd/linkerd-viz \
    -f ${YAML_LINKERD_VIZ} 
}

install_flagger() {
  helm upgrade --install flagger flagger/flagger --version ${FLAGGER_VERSION_CHART} \
    --namespace=linkerd \
    --set logLevel=info \
    --set crd.create=false \
    --set meshProvider=linkerd \
    --set metricsServer=http://prometheus-operated.kube-prometheus-stack:9090 
}

delete_control_plane() {
  helm delete linkerd
}

delete_viz() {
  helm delete linkerd-viz
}

delete_flagger() {
  helm delete flagger -n linkerd
}

main() {

    local OPTION=${1}

    case ${OPTION} in
        --install)
            add_update
            install_control_plane
            install_viz
            install_flagger
        ;;
        --delete)
            delete_control_plane
            delete_viz
            delete_flagger
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