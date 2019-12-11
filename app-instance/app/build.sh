#!/bin/bash

export GOPATH="$HOME/go"
export PATH=$PATH:$GOPATH/bin

# Check if dep doesn't exist
if ! [ -x "$(command -v dep)" ]; then
	curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
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

rm -rf output/conf.toml