
# Create a new project and link it to your billing account:
gcloud projects create ${TF_PROJECT_ID} --set-as-default
gcloud beta billing projects link ${TF_PROJECT_ID} --billing-account ${TF_BILLING_ACCOUNT_ID}

#Create the service account in the Terraform admin project and download the JSON credentials:

gcloud iam service-accounts create terraform --display-name 'Terraform admin account'
gcloud iam service-accounts keys create ${TF_CREDS} --iam-account terraform@${TF_PROJECT_ID}.iam.gserviceaccount.com

#Grant the newly created service account permissions:
gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} --member serviceAccount:terraform@${TF_PROJECT_ID}.iam.gserviceaccount.com --role roles/viewer
gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} --member serviceAccount:terraform@${TF_PROJECT_ID}.iam.gserviceaccount.com --role roles/storage.admin
gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} --member serviceAccount:terraform@${TF_PROJECT_ID}.iam.gserviceaccount.com --role roles/container.admin
gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} --member serviceAccount:terraform@${TF_PROJECT_ID}.iam.gserviceaccount.com --role roles/iam.serviceAccountUser

# Terraform related services
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable serviceusage.googleapis.com

# Create a bucket in Cloud Storage:
gsutil mb -p ${TF_PROJECT_ID} gs://${TF_PROJECT_ID}

# Enable versioning
gsutil versioning set on gs://${TF_PROJECT_ID}

# Configure your environment for the Google Cloud Terraform provider:

export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}
export GOOGLE_PROJECT=${TF_PROJECT_ID}

cat > backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "${TF_PROJECT_ID}"
    prefix = "terraform/state"
  }
}
EOF
