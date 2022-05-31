# Functions with OpenFaaS

## Prerequisites

You need a faasd server running somewhere. You can spin one up in te cloud using Terraform or locally using Multipass (see `infrastructure/` folder).

## Getting started

### 1. Installation

The installation of OpenFaaS cli tool can be found [here](https://docs.openfaas.com/cli/install/).

### 2. Log in to the OpenFaaS gateway with faas-cli

> For this step you need a faasd server running either locally using multipass or in the cloud (see `infrastructure/` folder).

To the OpenFaaS gateway username is `admin` by default and the password is found in the file located at `/var/lib/faasd/secrets/basic-auth-password` on the server where faasd is running.

If you can ssh into the server using assymetric keys, you can execute this on your local machine:

```bash
$ ssh ubuntu@<remote machine> "sudo cat /var/lib/faasd/secrets/basic-auth-password" > basic-auth-password
$ echo basic-auth-password | faas login -s
```

This assumes you have the `$OPENFAAS_URL` environment variable set to the gateway of your faasd server. If not you can use the `faas login`'s `-g` flag for example:

```bash
$ echo basic-auth-password | faas login -s -g https://<IP>:8080
```

## Usage

### Log into the GUI

The URL of the GUI is either `https://<domain>/ui` or `https://<ip>:8080/ui`.

The default username is `admin` and the password can acquired by looking at the Terraform state or by executing `sudo cat /lib/var/faasd/secrets/basic-auth-password` on the machine faasd is running on.

### Creating functions

[Official documentation](https://docs.openfaas.com/cli/templates/)

#### 1. List & describe templates from the store

```bash
faas-cli template store list
```

```bash
faas-cli template store describe golang-http
```

#### 2. Pull a template

```bash
faas-cli template store pull golang-http
```

> Prefer http versions of function templates. They use of-watchdog instead of classic-watchdog and are more performant. [More info](https://docs.openfaas.com/architecture/watchdog/)

#### 3. List available local templates

```bash
faas-cli new --list
```

#### 4. Create a new function

```bash
faas-cli new --lang golang-http hello-go --append=stack.yml
```

> I recommend using only a single `stack.yml` file and appending all new function to it, instead of a separate `<function-name>.yml` file for each function.

> Any extra files you place inside a function folder will also be available to the function inside the final container.

### Deploying functions

`faas-cli build`, `faas-cli push` and `faas-cli deploy` can be combined in a single command: `faas-cli up`.

There is a third command: `faas-cli publish` that combines `faas-cli build` and `faas-cli push` and enables multi-arch containers using Docker buildx.

When deploying function to anything different than your local machine, we shouldn’t use `faas up` because this does not take into account the differences in architecture between local and remote machine. I had the problem using an m1 Mac: `faas-cli up` wouldn’t work because I was building the images on arm64 and GC Compute Instances are amd64/x86-64.
- <https://docs.openfaas.com/cli/templates/>
- <https://github.com/openfaas/templates/issues/232>
- <https://docs.openfaas.com/cli/build/>

So, to cross compile you need to use the `publish` and `deploy` commands separately:

```bash
faas-cli publish —platforms linux/amd64 && faas deploy
```

### Scheduled functions (cron)

Scheduled functions only work if you have cron-connector installed. This is done automatically if you deployed the faasd server using this repo. If not you need to manually add cron-connector to faasd's `docker-compose.yml` file and restart faasd. Explained [here](https://libraries.io/go/github.com%2Fopenfaas-incubator%2Fcron-connector).

## Function timeouts

https://github.com/openfaas/faasd/issues/69


https://github.com/DriesCruyskens/faasd/blob/master/docker-compose.yaml

## Troubleshooting

- Help about `faas-cli` commands and subcommands, ex:
  - `faas-cli -h`
  - `faas-cli new -h`
  - `faas-cli up -h`
- Check function logs:
  - `faas-cli logs <function-name>`
- Check function status:
  - `faas-cli describe <function-name>`