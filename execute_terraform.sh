#!/bin/bash

# Check if setup has already been run, don't execute again.
# Terragrunt will fit in perfectly here... :)
if [ ! -f "setup/state" ]; then
    cd setup
    terraform init
    terraform validate
    terraform plan -out state -var-file=../config.tfvars
    terraform apply state
    cd ..
fi

terraform init -backend-config=config.tfvars
terraform validate
terraform plan -out state -var-file=config.tfvars
terraform apply state

echo "Done!"