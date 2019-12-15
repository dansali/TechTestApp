#!/bin/bash

echo "Init script started!"

export DATABASE_HOST="${dbhost}"
export DATABASE_PORT="${dbport}"
export DATABASE_NAME="${dbname}"
export DATABASE_USERNAME="${databaseusername}"
export DATABASE_PASSWORD="${databasepassword}"

echo '"DbUser" = "${databaseusername}"
"DbPassword" = "${databasepassword}"
"DbName" = "${dbname}"
"DbPort" = "${dbport}"
"DbHost" = "${dbhost}"
"ListenHost" = "0.0.0.0"
"ListenPort" = "3000"' > /tmp/app-instance/app/conf.toml

chown ec2-user:ec2-user /tmp/app-instance/app/conf.toml

# Lot of work to get the docker containers not to run as root, lol.
sudo su ec2-user -p -c 'DATABASE_HOST="${dbhost}"; DATABASE_PORT="${dbport}"; DATABASE_NAME="${dbname}"; DATABASE_USERNAME="${databaseusername}"; DATABASE_PASSWORD="${databasepassword}"; cd /tmp/app-instance; /usr/local/bin/docker-compose up'

echo "Init script done!"