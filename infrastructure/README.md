# Terraform for Google Cloud with faasd, cron-connector and caddy

> If you want to use a simpler local faasd instance instead of a cloud one, use [Multipass](<https://github.com/openfaas/faasd/blob/master/docs/MULTIPASS.md>) but use the included `infrastructure/cloud-config.txt` cloud config instead of the original one if you want cron-connector. 
> ```bash
> cat cloud-config.txt | multipass launch --name faasd --cloud-init -
> ```
> 
> This cloud-config can also be used when spinning up a VM anywhere else in the cloud or locally. More info about cloud-init and cloud-config [here](https://help.ubuntu.com/community/CloudInit) and [here](https://cloudinit.readthedocs.io/en/latest/topics/format.html).

## Getting started

### 1. Install terraform

<https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/gcp-get-started>

### 2. Get google credentials key

Follow these instructions

<https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build?in=terraform/gcp-get-started#set-up-gcp>

Place the key inside the `infrastructure/` folder

### 3. Set input variables

`cp terraform.tfvars.example terraform.tfvars`

And and change / fill in the input variables you want to use. Important ones are path to the google credentials file (see step 2) and `ssh_rsa_pub` which you can acquire using `cat ~/.ssh/id_rsa.pub` on your host computer. Passing your ssh public key will allow you to ssh into the created Compute Instace using `ssh ubuntu@<VM IP or domain>` after applying the Terraform plan.

### 4. Terraform backend

It is highly recommended to use a [terraform backend](https://www.terraform.io/language/settings/backends) to handle terraform's state. If used as is, this template will store the state locally. Uncomment the `Terraform { cloud {}}` block in `main.tf` and configure it to use [terraform cloud](https://www.terraform.io/language/settings/terraform-cloud) to store the state in the cloud and prevent headaches in the future.

If you don't want a google credentials file in your repo, you can put it as a Terraform Cloud environment variable instead. More info [here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#adding-credentials).

## Usage

### `terraform validate`

will validate the `*.tf` files.

### `terraform plan`

will show you what terraform will change to the current state of the cloud project. This can be done safely without consequences.

### `terraform apply`

will also show you what terraform will change and execute the changes after you accept them.

### `terraform destroy`

will do the opposite of the `terraform apply` command and undo all changes made.

## SSL

When the `domain` and `letsencrypt_email` input variables are present and valid, [Caddy](https://caddyserver.com/) will be installed and automatically provide SSL on port `443`. After deployment using Terraform you will know the external fixed IP address of the VM. This IP can be used to make a DNS record of the same `domain` you gave as input variable.

When `domain` and `letsencrypt_email` are not present, Caddy is not installed ant the faasd server is accessable on port `8080`

## Sensitive output variables

Senstitive output variables will be redacted in the CLI's output. These variables are available in terraform's state (locally or in terraform cloud, depending on what you configured). You will need the `basic_auth_password` to log into the OpenFaaS's ui at `https://<VM IP or domain>/ui`.

## cron-connector

The official OpenFaaS documentation is very cryptic when it comes the the `cron-connector` and scheduled functions. After a lot of research I [found the solution](https://libraries.io/go/github.com%2Fopenfaas-incubator%2Fcron-connector) and incorporated it into this template. The changes made are done in [my fork of the faasd repo](https://github.com/DriesCruyskens/faasd) in the `hack/instal.sh` script and `docker-compose.yml` file. It is the `infrastructure/cloud-init.tftpl` file in this project that gets the install script from my repo instead of the  original one.

## Troubleshooting

- Check status of services:
  - `sudo systemctl status faasd`
  - `sudo systemctl status faasd-provider`
  - `sudo systemctl status caddy`
- Check the status of cloud-init: 
  - `cloud-init status --wait`
- Check the logs of cloud-init: 
  - `sudo less /var/log/cloud-init-output.log`  
  - (and less importantly `sudo less /var/log/cloud-init.log`)
- Verify the cloud-config.txt file you passed to the VM
  - `locate user-data.txt`
  - `sudo less user-data.txt`

## References

- <https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code?in=terraform/gcp-get-started>