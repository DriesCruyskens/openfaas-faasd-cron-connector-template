variable "name" {
  description = "The name of the faasd instance."
  type        = string
}

variable "project" {
  description = "The id of the GCP Project where all resources will be launched."
  type        = string
  default     = null
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "google_credentials_file" {
  description = "The google credentials file used to authenticate with the Google Cloud project"
  type        = string
  default     = null
}

variable "ssh_rsa_pub" {
  default     = ""
  type        = string
  description = "Your public key string"
}

variable "domain" {
  description = "A public domain for the faasd instance. This will the use of Caddy and a Let's Encrypt certificate"
  type        = string
  default     = ""
}

variable "letsencrypt_email" {
  description = "Email used to order a certificate from Let's Encrypt"
  type        = string
  default     = ""
}

variable "basic_auth_user" {
  description = "The basic auth user name."
  type        = string
  default     = "admin"
}

variable "network" {
  description = "The name of the VPC Network where all resources should be created."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The name of the VPC Subnetwork where all resources should be created. Defaults to the default subnetwork for the network and region."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "The machine type of the Compute Instance to use for the faasd instance (e.g. e2-micro)."
  type        = string
  default     = "e2-medium"
}

variable "tags" {
  description = "A list of the tags to be applied to the Compute Instance."
  type        = list(string)
  default     = ["faasd"]
}