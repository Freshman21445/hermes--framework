#!/bin/bash
# Hermes project directory setup

mkdir -p hermes/{src/network,src/config,src/utils,plugins,server/{handlers,db,api,web,crypto,dns},config,docs,scripts}
cd hermes
git init
echo "Hermes project structure created."
