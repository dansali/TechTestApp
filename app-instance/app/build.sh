#!/bin/bash

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

cp -R $GOPATH/src/github.com/vibrato/TechTestApp/dist/* .

rm -rf output/conf.toml
cp /tmp/conf.toml .

./TechTestApp serve