# Base para desenvolvimento com NestJS

## Conteúdo

- [Visão geral](#visão-geral)
- [Instalação](#instalação)
- [Variáveis de ambiente](#variáveis-de-ambiente)
  - [USER_UID](#user_uid)
  - [NODE_ENV](#node_env)
  - [IMAGE_NAME](#image_name)
  - [IMAGE_TAG](#image_tag)
  - [WORK_DIR](#work_dir)
  - [HOST_PORT](#host_port)

- [Compilando uma imagem](#compilando-uma-imagem)
- [Criando uma nova aplicação](#criando-uma-nova-aplicação)


## Visão geral
Por padrão a imagem usa as seguintes versões:
- Alpine 3.17.0
- Node 19.3.0
- Yarn 1.22.19
- NestJS 9.1.5

[ONBUILD](https://docs.docker.com/engine/reference/builder/#onbuild) é usado para remover da imagem totalmente npm, yarn e o usuário node padrão, pois ele usa como uid/gid padrão 1001, o que dificulta para alguns usuários que não tem esse uid em seu usuário no host. Contudo, é instalado um novo Yarn e criado um novo usuário com o nome do ambiente (definido em NODE_ENV) colocado no mesmo grupo definido na variável de ambiente [USER_UID](#user_uid) - Se você não definir essa variável a imagem será construída com um UID diferente e isso no ambiente de desenvelmento vai lhe causar problemas de permissões nos arquivos.

## Instalação
Clone o repositório em seu ambiente e vá para o direório criado

```
$ git clone git@github.com:jacksonbicalho/nestjs-base-docker.git sua-app

$ cd sua-app

$ cp example.docker-compose.yml docker-compose.yml

$ cp example.env .env

```

## Variáveis de ambiente
Tenha em mente que o ambiente é pensado para o desenvolvimento e como a imagem é compilada neste momento,
pense apenas em ARGS por enquanto, pois são com eles que lidamos durante a compilação da imagem,
já que a compilação não tem acesso a variáveis de ambiente. Por outro lado, uso algumas variáveis de
ambiente no docker-compose.yml

### USER_UID
Se você definir USER_UID, a imagem criará um grupo e um usuário para ser usado no ambiente. Isso lhe facilitará com permissões durante o desenvolvimeneto se você usar o mesmo UID de seu usuário de sua máquina HOST. Para saber o seu, use em seu terminal:

 ```
 $ echo $(id -u))
 ```
### NODE_ENV
Durante o desenvolvimento, lembre-se de definir sempre NODE_ENV como development.

```
NODE_ENV=development
```

### IMAGE_NAME
Defina um nome para ser usado na construção da imagem [Referência](https://docs.docker.com/engine/reference/commandline/tag/)

```
IMAGE_NAME=jacksonbicalho/docker-nestjs-base
```

### IMAGE_TAG
Defina um tag para versionar sua imagem [Referência](https://docs.docker.com/engine/reference/commandline/tag/)

```
IMAGE_TAG=dev

```
### WORK_DIR
Se você não definir WORK_DIR, a imagem usará como padrão /usr/src/app. Lembre-se de mapear o volume corretamente se você não usar o docker-compose que segue como exemplo
```
WORK_DIR=/usr/src/app
```

### HOST_PORT
HOST_PORT só é usado no docker-compose de exemplo para mapear a porta de seu host com a porta 3000 do container criado
```
HOST_PORT=3000
```

## Compilando uma imagem
```
$ NODE_ENV=development docker-compose build --force-rm
```

## Criando uma nova aplicação
```
$ NODE_ENV=development docker-compose run --rm \
 nest nest new gateway \
 --directory=./ \
 --skip-git --package-manager \
 yarn --language TS
```
