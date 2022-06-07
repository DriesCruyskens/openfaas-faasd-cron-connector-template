# Functions with OpenFaaS

## Prerequisites

You need a faasd server running somewhere. You can spin one up in te cloud using Terraform or locally using Multipass (see `infrastructure/` folder).

## Getting started

### 1. Installation

The installation of OpenFaaS cli tool can be found [here](https://docs.openfaas.com/cli/install/).

### 2. Log in to the OpenFaaS gateway with faas-cli

> For this step you need a faasd server running either locally using multipass or in the cloud (see `infrastructure/` folder).

To the OpenFaaS gateway username is `admin` by default and the password is found in the file located at `/var/lib/faasd/secrets/basic-auth-password` on the server where faasd is running.

If you can ssh into the server using authorized_keys, you can execute this on your local machine:

```bash
$ ssh ubuntu@<remote machine> "sudo cat /var/lib/faasd/secrets/basic-auth-password" | faas login -s
```

This assumes you have the `$OPENFAAS_URL` environment variable set to the gateway of your faasd server. If not you can use the `faas login`'s `-g` flag for example:

```bash
$ echo basic-auth-password | faas login -s -g https://<IP>:8080
```

### 3. Configure an image registry

>tldr; If you're using public images and Docker Hub, just log into Docker Desktop and use your Docker Hub username as the image prefix.
>
> If you want to use private images, read on.

OpenFaaS uploads the functions' images to an image registry when deploying. If the images can be public I recommend using either Docker Hub or Github Container Registry. There are a lot of other image registries out there like Google Cloud Image Registry.

#### Public images

When using public images, you just have to make sure that the `image` fields in `stack.yml` have the right prefixes. By default a functions name would be `hello-go:latest` which would store the image in the local Docker Desktop image registry. In order for OpenFaaS to know where to upload the images we need to prefix it: `<Docker Hub username>/hello-go:latest` or `ghcr.io/<username>/hello-go:latest`. Of course, OpenFaaS needs to be able to authenticate with your chosen image registry. It does this using the `~/.docker/config.json` file on your local machine. If you are logged into Docker Desktop you should already find a `https://index.docker.io/v1/` entry here.

If you are using any other image registry than Docker Hub you need to add an entry to this file using the `docker login` command. [More info](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry).

#### Private images

The same applies here as with public images but because the images also need to be pulled on the faasd server, faasd needs to be able to authenticate with our private image registry. This is done using the `/var/lib/faasd/.docker/config.json` file on the faasd server. If your `~/.docker/config.json` file contains the auth string, you can copy this over to the server. On MacOS and Windows though, chances are the auth string is saved in keychain/credential manager. If this is the case you can generate the Docker config file using

```bash
faas-cli registry-login --server <server> --username <username> --password-stdin
```

For example `faas registry-login --server ghcr.io -u <username> --password-stdin`. If you are using ghcr, the password will be a Personal Access Token. (see the more info link under public images)


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
faas-cli new --lang golang-http hello-go --append=stack.yml --prefix <prefix>
```

The prefix gets prepended to the function's image. If you're using Docker Hub it is your username. If you're using ghcr.io it's `ghcr.io/<username>` etc. For example, the image field in `stack.yml` would then become `ghcr.io/<username>/hello-go:latest` instead of `hello-go:latest` 

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

### Logging in functions

#### classic-watchdog
Because classic-watchdog uses Stdin to pass the HTTP request and Stdout/Stderr to read the HTTP response you can do either:

- Enable `write_debug` to also write Stdout and Stderr to the logs, or
- Disable `combine_output` and write logs to `stderr`.

#### of-watchdog

You can either write to Stdout or Stderr to log.

### Scheduled functions (cron)

Scheduled functions only work if you have cron-connector installed. This is done automatically if you deployed the faasd server using this repo. If not you need to manually add cron-connector to faasd's `docker-compose.yml` file and restart faasd. Explained [here](https://libraries.io/go/github.com%2Fopenfaas-incubator%2Fcron-connector).

### Testing functions before deploying

[Official answer](https://docs.openfaas.com/deployment/troubleshooting/#i-want-to-test-my-function-without-deploying-it)

My recommendations: 
    - Write unit tests 
    - Deploy to local multipass VM

## Function timeouts

After installing faasd, function timeouts are set to 60s. To increase the timeout duration, you have to change it in 3 places. Whichever place has the lowest timeout configured, will be the effective timeout.

### 1. stack.yml (function timeouts)

```yaml
environment:
  write_timeout: 3m30s
  read_timeout: 3m
  exec_timeout: 3m
```

<https://github.com/openfaas/workshop/blob/master/lab8.md#extend-timeouts-with-read_timeout>

### 2. docker-compose.yml (faasd timeouts)

The gateway service in `/var/lib/faasd/docker-compose.yml` has 3 timeouts you have to increase. Make sure to restart faasd using `sudo systemctl restart faasd`

```
gateway:
  image: ghcr.io/openfaas/gateway:0.21.4
  environment:
  ...
    - read_timeout=60s
    - write_timeout=60s
    - upstream_timeout=65s
  ...
```

### 3. faasd-provider.service (faasd-provider gateway timeout)

You have to create a new file called `/etc/systemd/system/faasd-provider.service.d/override.conf` that increases the `faasd-provider` systemd service's timeout and restart the `faasd-provider` service.

```bash
mkdir /etc/systemd/system/faasd-provider.service.d
touch /etc/systemd/system/faasd-provider.service.d/override.conf
printf "[Service]\nEnvironment=\"service_timeout=5m\"\n" > /etc/systemd/system/faasd-provider.service.d/override.conf
systemctl restart faasd-provider
```

- <https://github.com/openfaas/faasd/issues/69#issuecomment-816856958>

### Timeout References

- <https://docs.openfaas.com/tutorials/expanded-timeouts/>
- <https://github.com/alexellis/go-long>

## Scaling to zero

Part of OpenFaaS Pro :(

## Troubleshooting

- Help about `faas-cli` commands and subcommands, ex:
  - `faas-cli -h`
  - `faas-cli new -h`
  - `faas-cli up -h`
- Check function logs:
  - `faas-cli logs <function-name>`
- Check function status:
  - `faas-cli describe <function-name>`
- Official troubleshooting guide:
  - <https://docs.openfaas.com/deployment/troubleshooting/>

## Handy links

- <https://github.com/openfaas/workshop>