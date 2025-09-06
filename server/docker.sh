#!/bin/sh

REG='merlos'

REPO='sensei'

# Version YYYY-MM-DD
VERSION=$(date +'%Y-%m-%d')

# Build for amd64 
docker build --platform linux/amd64 -t $REG/$REPO:latest -t $REG/$REPO:$VERSION .

# Push to repository
docker push $REG/$REPO:latest
docker push $REG/$REPO:$VERSION