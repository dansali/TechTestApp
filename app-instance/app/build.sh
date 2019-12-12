#!/bin/bash

# Set gopath if it doesn't exist.
if [ -z "$GOPATH" ]; then
	export GOPATH="$HOME/go"
fi

export PATH=$PATH:$GOPATH/bin

# Check if dep doesn't exist
if ! [ -x "$(command -v dep)" ]; then
	curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
	#go get -u github.com/golang/dep/cmd/dep
fi

go get -d github.com/vibrato/VibratoTechTest

LOCATION=$(pwd)
cd $GOPATH/src/github.com/vibrato/TechTestApp
chmod +x build.sh
./build.sh
cd $LOCATION

mkdir -p output
rm -rf output/*
cp -R $GOPATH/src/github.com/vibrato/TechTestApp/dist/* output

cd output
rm -rf conf.toml
cp /tmp/app-instance/app/conf.toml .

./TechTestApp serve