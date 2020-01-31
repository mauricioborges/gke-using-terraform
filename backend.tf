terraform {
  backend "gcs" {
    bucket = "terraform-gke-playground"
    prefix = "terraform/state"
  }
}
