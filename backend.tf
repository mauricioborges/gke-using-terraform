terraform {
  backend "gcs" {
    bucket = "gke-using-terraform"
    prefix = "terraform/state"
  }
}
