#!/bin/bash

# Set gopath if it doesn't exist.
if [ -z "$GOPATH" ]; then
	export GOPATH="$HOME/go"
fi

export PATH=$PATH:$GOPATH/bin

echo "Docker app build script started!"

# Check if dep doesn't exist
if ! [ -x "$(command -v dep)" ]; then
	#curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
	echo "Installing dep"
	go get -u github.com/golang/dep/cmd/dep
fi

echo "Installing the app"
go get -d github.com/servian/TechTestApp

echo "Building the app"
LOCATION=$(pwd)
cd $GOPATH/src/github.com/servian/TechTestApp
chmod +x build.sh
./build.sh

cd $LOCATION
mkdir -p output
rm -rf output/*
cp -R $GOPATH/src/github.com/servian/TechTestApp/dist/* output

cd output
rm -rf conf.toml
ln -s /tmp/app-instance/app/conf.toml conf.toml

echo "Installing psql"
apt-get update
apt-get install -y postgresql-client

echo "Check if we need new table or not"
export PGPASSWORD="$DATABASE_PASSWORD"
data=(`psql -w -d $DATABASE_NAME -h $DATABASE_HOST -p $DATABASE_PORT -U $DATABASE_USERNAME -c 'SELECT table_schema,table_name FROM information_schema.tables;'`)
if printf -- '%s\n' "${data[@]}" | grep -q "tasks"; then
	echo "Tasks table found, not creating."
else
	echo "Tasks table not found, creating."
	./TechTestApp updatedb -s
fi

echo "Starting app"
./TechTestApp serve