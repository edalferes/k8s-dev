# Linkerd

## Instalar o client

```bash
$ wget https://github.com/linkerd/linkerd2/releases/download/stable-2.10.2/linkerd2-cli-stable-2.10.2-linux-amd64
$ chmod +x linkerd2-cli-stable-2.10.2-linux-amd64
$ sudo mv linkerd2-cli-stable-2.10.2-linux-amd64 /usr/local/bin/linkerd
```

## Instalar o Server

Para gerenciar o linkerd no cluster execute o script **linkerd_init.sh ** abaixo na pasta $(pwd)/helm/linkerd

```bash
Script: init.sh
Maintainer: edmilson.alferes <edmilson.alferes@gmail.com>
Description: Script for managment linkerd

 Use option to script: 

 --install                 - Install helm linkerd
 --upgrade                 - Upgrade helm linkerd
 --delete                  - Delete helm linkerd
 --help | -h               - Show this info.
```