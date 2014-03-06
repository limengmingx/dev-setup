#!/bin/sh

STUCCO_HOME=/stucco
STUCCO_DATA_DIR=${STUCCO_HOME}/data

echo "Installing Stucco components..."

sudo mkdir -p $STUCCO_HOME
sudo chmod 4777 $STUCCO_HOME
sudo chown vagrant:vagrant $STUCCO_HOME

mkdir $STUCCO_DATA_DIR

### Download the repositories
cd $STUCCO_HOME
repos="ontology config-loader rt collectors document-service endogenous-data-uc1 get-exogenous-data"
for repo in $repos; do
  IFS=" "
  echo "cloning ${repo}"
  git clone --recursive https://github.com/stucco/${repo}.git
done

# Download exogenous data and put in data dir
cd $STUCCO_HOME/get-exogenous-data
npm start
mv data/* $STUCCO_DATA_DIR

# Move endogenous data into data dir
cd $STUCCO_HOME/endogenous-data-uc1
mv * $STUCCO_DATA_DIR

# Load configuration into etcd
cd $STUCCO_HOME/config-loader
NODE_ENV=vagrant node load.js

# Compile rt
cd $STUCCO_HOME/rt
./maven-rt-build.sh
cd stucco-topology
mvn clean package

# Install node modules and start document-service
cd $STUCCO_HOME/document-service
npm install --quiet

echo "Stucco has been installed."