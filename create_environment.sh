
cat > $1.tfvars << EOF
project = "${TF_PROJECT_ID}"
region = "us-east1"
general_purpose_machine_type = "n1-standard-1"
general_purpose_min_node_count = 1
general_purpose_max_node_count = 3
EOF

terraform workspace new $1
terraform plan -var-file=$1.tfvars
terraform apply -var-file=$1.tfvars
