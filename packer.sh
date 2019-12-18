#!/bin/bash

# Freshly builds clean amis
export AWS_SHARED_CREDENTIALS_FILE=$(pwd)/secret/credentials.ini

cd packer
packer validate centos7-updated-ami.json
packer validate techtest-app-node-ami.json
packer build centos7-updated-ami.json
packer build techtest-app-node-ami.json

echo "Done!"