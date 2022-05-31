# OpenFaaS and faasd template for Google Cloud Project

This repo serves a a template to get both [OpenFaaS](https://www.openfaas.com/) and [faasd](https://github.com/openfaas/faasd) up and running as quickly as possible. The recommended way to get use OpenFaaS is with Kubernetes but faasd is easier to set up, maintain, and requires only a single VM and less resources.

The faasd repo already provides easy ways to install it either through [terraform](https://github.com/jsiebens/terraform-google-faasd), [cloud-init](https://blog.alexellis.io/deploy-serverless-faasd-with-cloud-init/) and/or and [install script](https://github.com/DriesCruyskens/faasd/blob/master/hack/install.sh). The reason I made this repo is because none of those install faasd with the OpenFaaS [cron-connector](https://docs.openfaas.com/reference/cron/#faasd) which allows for scheduled functions using cron notation.

This repo is made out of two parts: infrastructure and functions.

## Infrastructure/

The infrastructure directory contains files that allow for easy deployment of [faasd](https://github.com/openfaas/faasd) to a Google Cloud Platform project. It makes use of Terraform to provision a compute instance and cloud-init to intialise the compute instance with faasd. The advantage of Terraform is that your cloud infrastructure is declared in files so it can be version controlled, easily created and destroyed without forgetting things or making mistakes (which is more likely to occur when configuring the cloud manually through the GUI).

More info can be found in `infrastructure/README.md`.

## Functions/

This folder contains everything related to OpenFaaS. 

More info can be found in `functions/README.md`