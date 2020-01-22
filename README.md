# Setup GKE using Terraform

## Before you begin

1. Install Terraform

```sh
brew install terraform
```

2. Install Kubernetes CLI (kubectl)

```sh
$ brew install kubectl
```

3. Install Google Cloud SDK (gcloud, gsutil and friends)

```sh
$ brew cask install google-cloud-sdk
```

## Get a Google Cloud account (if you do not have one already)

If you do not have an [Google Cloud](https://cloud.google.com/) account, you can benefit from getting
access to a free tier one. Google Cloud offers $300,00 of free credits
which you can spend on the following to 12 months.

## Set up your environment

### Configuring Google Cloud SDK

Once you have installed Google Cloud SDK you can authenticate with your
account:

```sh
$ gcloud init
```

This will open a new browser window, asking you to login.

Then export the following environment variables that we will use throughout
this guide.

```sh
$ export TF_PROJECT_ID=gke-using-terraform
$ export TF_BILLING_ACCOUNT_ID=<YOUR_BILLING_ACCOUNT_ID>
$ export TF_CREDS=~/.config/gcloud/terraform-admin.json
```

You can get your billing account id running the following command:

```sh
$ gcloud beta billing accounts list
```

### Create a project

Create a new project and link it to your billing account:

```sh
$ gcloud projects create ${TF_PROJECT_ID} --set-as-default
$ gcloud beta billing projects link ${TF_PROJECT_ID} --billing-account ${TF_BILLING_ACCOUNT_ID}
```

### Create the Terraform service account

Create the service account in the Terraform admin project and download the JSON credentials:

```sh
$ gcloud iam service-accounts create terraform --display-name 'Terraform admin account'
$ gcloud iam service-accounts keys create ${TF_CREDS} --iam-account terraform@${TF_PROJECT_ID}.iam.gserviceaccount.com
```

Grant the newly created service account permissions to:

- View the Admin Project
- Manage Cloud Storage
- Manage Container Service
- Service Account User

```sh
$ gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} --member serviceAccount:terraform@${TF_PROJECT_ID}.iam.gserviceaccount.com --role roles/viewer
$ gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} --member serviceAccount:terraform@${TF_PROJECT_ID}.iam.gserviceaccount.com --role roles/storage.admin
$ gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} --member serviceAccount:terraform@${TF_PROJECT_ID}.iam.         gserviceaccount.com --role roles/container.admin
$ gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} --member serviceAccount:terraform@${TF_PROJECT_ID}.iam.         gserviceaccount.com --role roles/iam.serviceAccountUser
```

Terraform interacts with Google Cloud through its API. For
security reasons, you need to enable the APIs you want to use
for your project:

```sh
$ gcloud services enable cloudresourcemanager.googleapis.com
$ gcloud services enable cloudbilling.googleapis.com
$ gcloud services enable iam.googleapis.com
$ gcloud services enable compute.googleapis.com
$ gcloud services enable container.googleapis.com
$ gcloud services status serviceusage.googleapis.com
```

### Set up remote state

Terraform keeps track you your infrastructure through state files. When
you are working on a team, you need to share the state with your teammates.
Terraform support several
[backends](https://www.terraform.io/docs/backends/index.html) you could
use, including Google Cloud Storage.

Create a bucket in Cloud Storage:

```sh
$ gsutil mb -p ${TF_PROJECT_ID} gs://${TF_PROJECT_ID}
```

Enable versioning for the bucket:

```sh
$ gsutil versioning set on gs://${TF_PROJECT_ID}
```

Configure your environment for the Google Cloud Terraform provider:

```sh
$ export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}
$ export GOOGLE_PROJECT=${TF_PROJECT_ID}

$ cat > backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "${TF_PROJECT_ID}"
    prefix = "terraform/state"
  }
}
EOF
```

Next, initialize the backend:

```sh
$ terraform init
```

### Create a Terraform workspace

Terraform allows you to have workspace to isolate distinct environments.
In this example we will create a development environment.

```sh
$ cat > development.tfvars << EOF
project = "${TF_PROJECT_ID}"
region = "us-east1"
general_purpose_machine_type = "n1-standard-1"
general_purpose_min_node_count = 1
general_purpose_max_node_count = 3
EOF

$ terraform workspace new development
```

### Run terraform

Add the [cluster.tf](cluster.tf) to your folder and then run:

```sh
$ terraform plan -var-file=development.tfvars
$ terraform apply -var-file=development.tfvars
```

### Check if the cluster is working

Get the cluster credentials:

```sh
$ gcloud container clusters get-credentials gke-using-terraform-cluster --region us-east1 --project ${TF_PROJECT_ID}
```

Run a dummy container and expose it to the Internet:

```sh
$ kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
$ kubectl expose deployment hello-node --type=LoadBalancer --port=8080
```

After a few seconds, get service details to get the external IP address:

```sh
$ kubectl get services hello-node
```

And then send an HTTP request, using `curl` for example, to check if
everything is working:

```sh
$ curl <YOUR_EXTERNAL_IP_ADDRESS>:8080
```

## Clean up your environment

To avoid getting overcharged, after running all these steps, shutdown
your cluster by running:

```sh
$ terraform destroy
```

## Useful Resources

1. [Managing Google Cloud projects with Terraformk](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform)
2. [Google Cloud Platform Provider - Terraform Documentation](https://www.terraform.io/docs/providers/google/index.html)
3. [Kubernetes on GKE from scratch using Terraform](https://elastisys.com/2019/04/12/kubernetes-on-gke-from-scratch-using-terraform/)
