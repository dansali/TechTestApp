# Freshly builds clean amis
cd packer
packer build centos7-updated-ami.json
packer build techtest-app-node-ami.json