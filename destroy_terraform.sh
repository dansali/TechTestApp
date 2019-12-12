#!/bin/bash

terraform destroy -var-file=config.tfvars
rm -rf state
cd setup
terraform destroy -var-file=../config.tfvars
rm -rf state

echo "Done!"