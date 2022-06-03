/* terraform {
  cloud {
    organization = ""

    workspaces {
      name = ""
    }
  }
} */

provider "google" {
  # If google_credentials_file is not passed, assume GOOGLE_CREDENTIALS env var is set in Terraform Cloud
  credentials = var.google_credentials_file == null ? ("${var.google_credentials_file}") : null
}

resource "random_password" "faasd" {
  length  = 16
  special = false
}

resource "google_compute_address" "faasd" {
  project = var.project
  region  = var.region
  name    = var.name
}

resource "google_compute_instance" "faasd" {
  project      = var.project
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type

  metadata = {
    enable-oslogin = "TRUE"
    user-data = templatefile("cloud-config.tftpl", {
      ssh_rsa_pub         = var.ssh_rsa_pub
      basic_auth_password = random_password.faasd.result
      basic_auth_user     = var.basic_auth_user
      domain              = var.domain
      letsencrypt_email   = var.letsencrypt_email
    })
  }

  boot_disk {
    initialize_params {
      size = 20
      # https://console.cloud.google.com/compute/images
      # using ubuntu because it has cloud-init pre-installed
      # https://stackoverflow.com/questions/58248190/how-to-use-cloud-init-with-a-debian-based-image-on-google-cloud
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    access_config {
      nat_ip = google_compute_address.faasd.address
    }
  }

  tags = var.tags

  shielded_instance_config {
    enable_secure_boot = true
  }

}

resource "google_compute_firewall" "faasd_gateway" {
  project = var.project
  name    = format("%s-allow-gateway", var.name)
  network = var.network
  allow {
    protocol = "tcp"
    ports    = var.domain == "" ? ["8080"] : ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "faasd_ssh" {
  project = var.project
  name    = format("%s-allow-ssh", var.name)
  network = var.network
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}