#!/bin/bash
#
# Description: Script for install / update Kubernetes locally
# Maintainer: edmilson.alferes <edmilson.alferes@gmail.com>

# Global Variables
LOG_FILE="init.log"
INIT_CONFIG_FILE="init.conf"
REGISTRY_LOCAL_PORT="5000"
DEPLOY_PATH="deploy"
REG_NAME="kind-registry"
REG_PORT="5000"
KIND_IMAGE=""

info_header(){

    cat << "EOF"
  _  _____   _____       _____  ________      __
 | |/ / _ \ / ____|     |  __ \|  ____\ \    / /
 | ' / (_) | (___ ______| |  | | |__   \ \  / /
 |  < > _ < \___ \______| |  | |  __|   \ \/ /
 | . \ (_) |____) |     | |__| | |____   \  /
 |_|\_\___/|_____/      |_____/|______|   \/
EOF

    echo ""
    echo  "Script: init.sh"
    echo  "Maintainer: Infra <edmilson.alferes@gmail.com>"
    echo  "Description: Script for install / update Kubernetes locally"
}

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

help_info() {

    info_header

    echo ""
    echo " Use option to script: "
    echo ""
    echo " --create-cluster                     - run k8s cluster local using Kind"
    echo " --delete-cluster                     - delete k8s cluster local using Kind"
    echo " --create-deploy                      - Install base deploys for the local cluster."
    echo " --delete-deploy                      - Delete base deploys for the local cluster."
    echo " --help | -h                          - Show this info."
    echo ""
}

# If there is an error in executing the function, the program will be terminated
validate_function() {

    local result=${1}
    local func=${2}

    if [[ ${result} != 0 ]]; then
        log_error "validate_function" "Error executing function ${func}, stopping program execution..."
        exit 1
    fi
}

# Read key file config <key>
read_parameters () {

    local KEY=${1}
    RESULT=$(grep "${KEY}" ${INIT_CONFIG_FILE} | sed -nr "s/${KEY}:(.+)/\\1/p")
    echo ${RESULT}
}

validate_parameters() {

    if [ -e ${INIT_CONFIG_FILE} ]; then

        K8S_VERSION=$(read_parameters "K8S_VERSION")
        export K8S_VERSION_ENV="${K8S_VERSION}"

        IP_DOCKER_REGISTRY=$(read_parameters "IP_DOCKER_REGISTRY")
        export IP_DOCKER_REGISTRY_ENV="${IP_DOCKER_REGISTRY}"

        KIND_IMAGE=$(read_parameters "KIND_IMAGE")

	else
        log_error "validate_parameters" "Configuration file: ${INIT_CONFIG_FILE} not found."
        exit 1
    fi
}

check_app() {

    docker --version 2&> /dev/null
    if [[ ${?} != 0 ]]; then
        log_error "check_app" "The 'docker' was not found, install docker to continue."
        exit 1
    fi

    kind --version 2&> /dev/null
    if [[ ${?} != 0 ]]; then
        log_error "check_app" "The 'kind' app was not found, install kind to continue."
        exit 1
    fi
}

create_registry() {

    log_info "create_registry" "create registry container unless it already exists"

    running="$(docker inspect -f '{{.State.Running}}' "${REG_NAME}" 2>/dev/null || true)"
    if [ "${running}" != 'true' ]; then
    docker run \
        -d --restart=always -p "127.0.0.1:${REG_PORT}:5000" --name "${REG_NAME}" \
        registry:2
    fi
}

create_cluster() {

    log_info "create_cluster" "create a cluster with the local registry enabled in containerd"

    cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerPort: 6443
  disableDefaultCNI: true

nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "nodeapp=loadbalancer"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REG_PORT}"]
    endpoint = ["http://${REG_NAME}:${REG_PORT}"]
EOF
}

config_cluster() {

    log_info "config_cluster" "connect the registry to the cluster network"

    # (the network may already be connected)
    docker network connect "kind" "${REG_NAME}" 2>/dev/null || true

    log_info "config_cluster"  "Document the local registry"
    # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REG_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
}

install_tools() {

	log_info "install_tools" "Install default tools"

	# Get default gateway interface
	KIND_ADDRESS=$(docker network inspect kind | jq '.[].IPAM | .Config | .[0].Subnet' | cut -d \" -f 2 | cut -d"." -f1-3)

	# Radomize Loadbalancer IP Range
	KIND_ADDRESS_END=$(shuf -i 100-150 -n1)

	# Create address range
	KIND_LB_RANGE=$(echo $KIND_ADDRESS.$KIND_ADDRESS_END)

	# Transform IP address to Hexadecimal
	IP_HEX=$(echo $KIND_LB_RANGE | awk -F '.' '{printf "%08x", ($1 * 2^24) + ($2 * 2^16) + ($3 * 2^8) + $4}')

	# Ingress Address
	KIND_INGRESS_ADDRESS=$(echo $IP_HEX.nip.io)

	# Install and upgrade Helm repositories
	helm repo add projectcalico https://docs.projectcalico.org/charts
	helm repo add openebs-nfs https://openebs.github.io/dynamic-nfs-provisioner
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo add metallb https://metallb.github.io/metallb
	helm repo update

	# Install Calico and check if it is installed
	helm install calico projectcalico/tigera-operator \
		--namespace calico-system \
		--create-namespace \
		--version v3.20.0 \
        --wait

	# Install metrics-server and check if it is installed
	helm install metrics-server bitnami/metrics-server \
		--namespace kube-system \
		--set rbac.create=true \
		--set extraArgs.kubelet-insecure-tls=true \
		--set apiService.create=true \
		--version 5.11.1 \
        --wait

	# Install MetalLB and check if it is installed
		helm upgrade --install metallb metallb/metallb \
		--create-namespace \
		--namespace metallb-system \
		--set "configInline.address-pools[0].addresses[0]="$KIND_LB_RANGE/32"" \
		--set "configInline.address-pools[0].name=default" \
		--set "configInline.address-pools[0].protocol=layer2" \
		--set controller.nodeSelector.nodeapp=loadbalancer \
		--set "controller.tolerations[0].key=node-role.kubernetes.io/master" \
		--set "controller.tolerations[0].effect=NoSchedule" \
		--set speaker.tolerateMaster=true \
		--set speaker.nodeSelector.nodeapp=loadbalancer \
		--version 0.12.1 \
        --wait

	# Install Ingress and check if it is installed
	helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--create-namespace \
		--set controller.nodeSelector.nodeapp=loadbalancer \
		--set "controller.tolerations[0].key=node-role.kubernetes.io/master" \
		--set "controller.tolerations[0].effect=NoSchedule" \
		--set podLabels.nodeapp=loadbalancer \
		--set "service.annotations.metallb.universe.tf/address-pool=default" \
		--set defaultBackend.enabled=true \
		--set defaultBackend.image.repository=rafaelperoco/default-backend,defaultBackend.image.tag=1.0.0 \
		--set controller.watchIngressWithoutClass=true \
		--version 4.0.17 \
        --wait

	# Generate info DNS for use ingress
	echo "$KIND_INGRESS_ADDRESS" > ingress_address.txt
}

create_namespace() {

    log_info "create_namespace" "Create namespace for deploy application: ${NAMESPACE}"

    kubectl create ns ${NAMESPACE}
}

create_kind() {

    log_info "up" "Run Kind create"
    create_registry
    create_cluster
    config_cluster
	install_tools
}

delete_kind() {

    log_info "halt" "Run Kind delete"
    kind delete cluster
    docker stop kind-registry
    docker rm kind-registry
}

create_deploy(){

    deploy_list --install
}

delete_deploy(){

    deploy_list --delete
}

deploy_list() {

    script_options=${1}

    log_info "deploy" "extra deploy app k8s"

    options=$(ls deploy/ | awk '{print $1, "off"}')

    cmd=(dialog --stdout --no-items \
        --separate-output \
        --ok-label "Execute" \
        --checklist "Select the extra deploy to be $script_options:" 00 50 00)

    choices=$("${cmd[@]}" ${options})

    clear

    for dep in $choices
    do
        deploy_exec $dep ${script_options}
    done
}

deploy_exec() {

    deploy=${1}
    deploy_option=${2}

    log_info "deploy_exec" "$DEPLOY_PATH/$deploy | $deploy_option"

    cd $DEPLOY_PATH/$deploy

    script=$(find . -name '*.sh')

    ./$script $deploy_option

    cd ../..
}

main() {

    check_app
    validate_parameters

    local OPTION=${1}

    case ${OPTION} in
        --create-cluster)
            create_kind
        ;;
        --delete-cluster)
            delete_kind
        ;;
        --create-deploy)
            create_deploy
        ;;
        --delete-deploy)
            delete_deploy
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
