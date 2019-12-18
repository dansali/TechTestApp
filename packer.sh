#!/bin/bash

# Freshly builds clean amis
export AWS_SHARED_CREDENTIALS_FILE=$(pwd)/secret/credentials.ini

# if plugin not installed
if [ ! -f ~/.packer.d/plugins/packer-post-processor-amazon-ami-management ]; then
    echo "Installing packer amazon ami management!"
    mkdir -p ~/.packer.d/plugins
    wget https://github.com/wata727/packer-post-processor-amazon-ami-management/releases/download/v0.7.0/packer-post-processor-amazon-ami-management_0.7.0_darwin_amd64.zip -P /tmp/
    cd ~/.packer.d/plugins
    unzip -j /tmp/packer-post-processor-amazon-ami-management_0.7.0_darwin_amd64.zip -d ~/.packer.d/plugins
fi

cd packer
packer validate centos7-updated-ami.json
packer validate techtest-app-node-ami.json
packer build centos7-updated-ami.json
packer build techtest-app-node-ami.json

echo "Done!"