#!/bin/bash

# We can use this if you don't already have keys ready to use :)
ssh-keygen -b 2048 -t rsa -f secret/aws -q -N ""

echo "Done!"