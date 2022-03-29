# K8S-DEV

Este projeto tem como objetivo auxiliar as equipes em criar um cluster Kubernetes localmente para fins de desenvolvimento.

## Aplicando este repositorio como submodulo

Para aplicar este repo como submodulo em outros projetos execute:

```
git submodule add git@github.com:edalferes/k8s-dev.git
```

### Clonando um projeto com submódulos


Aqui vamos clonar um projeto com um submódulo nele. Quando você clona tal projeto, por padrão, você obtém os diretórios que contêm submódulos, mas nenhum dos arquivos dentro deles ainda:

```
git clone git@github.com:edalferes/MEU-PROJETO.git
```

O **k8s-dev** diretório está lá, mas vazio. Você deve executar dois comandos: **git submodule init** inicializar seu arquivo de configuração local e **git submodule update** buscar todos os dados desse projeto e verificar o commit apropriado listado em seu superprojeto.

Agora seu **k8s-dev** diretório está no estado exato em que estava quando você fez o commit anteriormente.

Há outra maneira de fazer isso que é um pouco mais simples, no entanto. Se você passar **--recurse-submodules** para o **git clone** comando, ele inicializará e atualizará automaticamente cada submódulo no repositório, incluindo submódulos aninhados se algum dos submódulos no repositório tiver submódulos.

```
git clone --recurse-submodules git@github.com:edalferes/MEU-PROJETO.git
```
Para atualizar o seu repositorio com a versao mais recente do k8s- configurado como submodule execute:

```
git submodule update --remote k8s-dev
```

## Kind

[kind](https://kind.sigs.k8s.io/) é uma ferramenta para executar clusters Kubernetes locais usando "nós" de contêiner do Docker.
kind foi projetado principalmente para testar o próprio Kubernetes, mas pode ser usado para desenvolvimento **local** ou **CI**.

## **Pré-requisitos**

> <font color="orange">Atenção</font>: Os testes deste projeto foram feitos em um ambiente Linux `ubuntu 20.04` como host de desenvolvimento, mas isso não impede de utilizá-lo em` Windows` ou `Windows com WSL`.

Para utilização do script em ambiente Linux, voce vai precisar executar:

```bash
$ sudo apt-get install docker.io dialog curl python jq -y
```

### **kind**

```bash
$ curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.0/kind-linux-amd64
$ chmod +x ./kind
$ sudo mv ./kind /usr/local/bin/kind
```

### **kubectl**

Instale o [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) cli em seu computador.

```bash
$ curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
$ chmod +x kubectl
$ sudo mv kubectl /usr/local/bin/
```

### **tilt**

`tilt` é uma ferramenta de linha de comando que facilita o desenvolvimento contínuo para aplicativos nativos do Kubernetes. O Tilt automatiza todas as etapas de uma mudança de código para um novo processo: assistir arquivos, construir imagens de contêiner e trazer seu ambiente atualizado. Pense docker **build && kubectl apply ou docker-compose up**.

```bash
$ curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash
```

### **Helm 3**

Helm é um gerenciador de pacotes de código aberto para Kubernetes. Ele fornece a capacidade de fornecer, compartilhar e usar software desenvolvido para Kubernetes.

```bash
$ curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

## Visão geral da configuração

A configuração do cluster Kubernetes, que consistirá em um nó mestre e dois nós de trabalho.

### Estrutura do projeto

Os arquivos e pastas mantidos no projeto são:

```
├── deploy
│   ├── ....
├── init.conf
├── init.sh
└── README.md
```

### Otimizando seu ambiente

Aqui está uma breve descrição de cada parâmetro que pode ser alterado.

### init.conf

| Parametro    | Descrição                                                                             | Valor Padrão            |
|--------------|---------------------------------------------------------------------------------------|-------------------------|
| `KIND_IMAGE` | Define qual image do kind sera utilizada (a imagem representa a versão do kubernetes) | `kindest/node:v1.20.2` |


## Provisionando o ambiente

```bash                                                                 
Script: init.sh
Maintainer: edmilson.alferes <edmilson.alferes@gmail.com>
Description: Script for install / update Kubernetes locally

 Use option to script: 

 --create-cluster                     - run k8s local using Kind
 --delete-cluster                     - delete k8s local using Kind
 --create-deploy                      - Install base deploys for the local cluster.
 --delete-deploy                      - Delete base deploys for the local cluster.
 --help | -h                          - Show this info.
```

## Criando o cluster local

Com os comandos **./init.sh --create-cluster** e .**/init.sh --delete-cluster** o desenvolvedor poderá criar / deletar o cluster localmente.

### Criando o cluster k8s localmente

```bash
$ ./init.sh --create-cluster

 [2021/07/29 12:36:03] - [INFO] - [up]: Run Kind create 
 [2021/07/29 12:36:03] - [INFO] - [create_registry]: create registry container unless it already exists 
 [2021/07/29 12:36:04] - [INFO] - [create_cluster]: create a cluster with the local registry enabled in containerd 
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.18.15) 🖼
 ✓ Preparing nodes 📦 📦 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
 ✓ Joining worker nodes 🚜 
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Thanks for using kind! 😊
 [2021/07/29 12:37:00] - [INFO] - [config_cluster]: connect the registry to the cluster network 
 [2021/07/29 12:37:01] - [INFO] - [config_cluster]: Document the local registry 
configmap/local-registry-hosting created

```

> <font color="orange">Atenção</font>: A execução deste comando alem de criar o cluster kubernetes tambem irá criar um registro de container local vinclulado ao cluster no endereço: **localhost:5000**

Após o comando ser executado com sucesso, valide a criação do cluster com os comando abaixo:

Validando endpoints do cluster:

```bash
$ kubectl cluster-info --context kind-kind

Kubernetes control plane is running at https://127.0.0.1:44201
KubeDNS is running at https://127.0.0.1:44201/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

```

**Para utilizar o contexto kind-kind em sua sessão de terminal;**

```bash
$ kubectl config  use-context kind-kind

```

Verificando os container docker do **kind** e **registry**.

```bash
$ docker ps -a

CONTAINER ID   IMAGE                   COMMAND                  CREATED         STATUS         PORTS                       NAMES
9bd6c12b9d51   kindest/node:v1.18.15   "/usr/local/bin/entr…"   3 minutes ago   Up 3 minutes                               kind-worker
657600388c9d   kindest/node:v1.18.15   "/usr/local/bin/entr…"   3 minutes ago   Up 3 minutes                               kind-worker2
f0fc4116d39d   kindest/node:v1.18.15   "/usr/local/bin/entr…"   3 minutes ago   Up 3 minutes   127.0.0.1:39107->6443/tcp   kind-control-plane
ae70b3f424cd   registry:2              "/entrypoint.sh /etc…"   3 days ago      Up 16 hours    127.0.0.1:5000->5000/tcp    kind-registry

```

Executando **kubectl** no cluster local.

```bash
$ kubectl get pod -A

NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
kube-system          coredns-66bff467f8-89mtt                     1/1     Running   0          4m57s
kube-system          coredns-66bff467f8-z7j8t                     1/1     Running   0          4m57s
kube-system          etcd-kind-control-plane                      1/1     Running   0          5m5s
kube-system          kindnet-44crb                                1/1     Running   2          4m39s
kube-system          kindnet-cs9fm                                1/1     Running   0          4m57s
kube-system          kindnet-dv4mz                                1/1     Running   2          4m39s
kube-system          kube-apiserver-kind-control-plane            1/1     Running   0          5m5s
kube-system          kube-controller-manager-kind-control-plane   1/1     Running   0          5m5s
kube-system          kube-proxy-7n9s7                             1/1     Running   0          4m39s
kube-system          kube-proxy-dbxd4                             1/1     Running   0          4m39s
kube-system          kube-proxy-jgv58                             1/1     Running   0          4m57s
kube-system          kube-scheduler-kind-control-plane            1/1     Running   0          5m4s
local-path-storage   local-path-provisioner-5b4b545c55-6phvv      1/1     Running   0          4m57s

```

### Removendo o cluster

```bash
$ ./init.sh --delete-cluster

[2021/07/29 12:43:57] - [INFO] - [halt]: Run Kind delete 
Deleting cluster "kind" ...
```
