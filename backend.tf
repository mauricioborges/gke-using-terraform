terraform {
  backend "gcs" {
    bucket = "gke-terraform-jenkinsx"
    prefix = "terraform/state"
  }
}
