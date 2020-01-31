variable "project" {
  type = string
  description = "Google Cloud project id"
}

variable "region" {
  type = string
  description = "Google Cloud region"
}

variable "general_purpose_machine_type" {
  type = string
  description = "Machine type to use for the general-purpose node pool. See https://cloud.google.com/compute/docs/machine-types"
}

variable "general_purpose_min_node_count" {
  type = string
  description = "The minimum number of nodes PER ZONE in the general-purpose node pool"
  default = 1
}

variable "general_purpose_max_node_count" {
  type = string
  description = "The maximum number of nodes PER ZONE in the general-purpose node pool"
  default = 5
}

resource "google_container_cluster" "cluster" {
  name = "${var.project}-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {
    username = ""
    password = ""
  }

  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  network_policy {
    enabled = true
    provider = "CALICO"
  }
}

resource "google_container_node_pool" "general_purpose" {
  name = "${var.project}-general"
  location = var.region
  cluster = google_container_cluster.cluster.name

  management {
    auto_repair = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = var.general_purpose_min_node_count
    max_node_count = var.general_purpose_max_node_count
  }
  initial_node_count = var.general_purpose_min_node_count

  node_config {
    preemptible = true
    machine_type = var.general_purpose_machine_type
    service_account = "terraform@${var.project}.iam.gserviceaccount.com"
    oauth_scopes = [
  "https://www.googleapis.com/auth/devstorage.read_only",
  "https://www.googleapis.com/auth/logging.write",
  "https://www.googleapis.com/auth/monitoring"
]
  }
}
