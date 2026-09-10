terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "burnished-stone-508009-m3"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# Removido data source para evitar erro de permissão.

# Instância Compute Engine
resource "google_compute_instance" "task_manager_vm" {
  name         = "task-manager-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  tags = ["http-server-3000"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Gera IP público
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y nodejs npm git

    git clone --branch main https://github.com/profdiegoluispires/task-manager.git /opt/task-manager
    cd /opt/task-manager
    npm install
    nohup npm start -- --port=3000 > /var/log/task-manager.log 2>&1 &
  EOT
}

# Firewall para permitir acesso à porta 3000
resource "google_compute_firewall" "allow_3000" {
  name    = "allow-task-manager-3000"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server-3000"]
}

# Cloud Storage: Criação de Bucket
resource "google_storage_bucket" "task_manager_bucket" {
  name          = "bucket-task-manager-burnished-stone-508009-m3"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true
}

# Cloud Storage: Envio de um arquivo
resource "google_storage_bucket_object" "sample_file" {
  name   = "sample_file.txt"
  bucket = google_storage_bucket.task_manager_bucket.name
  source = "sample_file.txt"
}

output "vm_public_ip" {
  description = "Acesse este IP na porta 3000"
  value       = "http://${google_compute_instance.task_manager_vm.network_interface[0].access_config[0].nat_ip}:3000"
}

output "bucket_url" {
  description = "Link do Bucket no Cloud Storage"
  value       = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.task_manager_bucket.name}"
}
