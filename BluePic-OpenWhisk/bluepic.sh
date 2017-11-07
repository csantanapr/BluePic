#!/bin/bash
#
# Copyright 2016 IBM Corp. All Rights Reserved.
# 
# Licensed under the Apache License, Version 2.0 (the “License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#  https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
 
# Color vars to be used in shell script output
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'
 
# load configuration variables
source local.env

# capture the namespace where actions will be created
# as we need to pass it to our change listener
AUTH_TOKEN=`wsk property get --auth | awk '{print $3}' | base64 -b=0`
CURRENT_NAMESPACE=$(curl -X GET -H "Authorization: Basic $AUTH_TOKEN"\
 -H "Content-Type: application/json" "https://openwhisk.ng.bluemix.net/api/v1/namespaces/_/"\
 | grep 'namespace'\
 | tail -1\
 | awk '{print $2}')
echo "Current namespace is $CURRENT_NAMESPACE."

function usage() {
  echo -e "${YELLOW}Usage: $0 [--install,--uninstall,--reinstall,--env]${NC}"
}

function install() {
  echo -e "${YELLOW}Installing OpenWhisk actions for BluePic..."
  
  echo "Creating package"
  wsk package create bluepic
  
  echo "Adding VCAP_SERVICES as parameter"
  wsk package update bluepic\
    -p visualRecognitionKey $VISUAL_key\
    -p weatherUsername $WEATHER_username\
    -p weatherPassword $WEATHER_password\
    -p cloudantHost $CLOUDANT_host\
    -p cloudantUsername $CLOUDANT_username\
    -p cloudantPassword $CLOUDANT_password\
    -p cloudantDbName $CLOUDANT_db\
    -p appIdClientId $AppID_client\
    -p appIdSecret $AppID_secret\
    -p kituraHost $KITURA_host\
    -p kituraPort $KITURA_port\
    -p kituraSchema $KITURA_schema\
    -p targetNamespace $CURRENT_NAMESPACE

  echo "Creating actions"
  wsk action create --kind swift:3.1.1 bluepic/weather actions/Weather.swift -t 300000
  wsk action create --kind swift:3.1.1 bluepic/visualRecognition actions/VisualRecognition.swift -t 300000
  wsk action create --kind swift:3.1.1 bluepic/cloudantRead actions/CloudantRead.swift -t 300000
  wsk action create --kind swift:3.1.1 bluepic/cloudantWrite actions/CloudantWrite.swift -t 300000
  wsk action create --kind swift:3.1.1 bluepic/kituraRequestAuth actions/KituraRequestAuth.swift -t 300000
  wsk action create --kind swift:3.1.1 bluepic/kituraCallback actions/KituraCallback.swift -t 300000
  wsk action create --kind swift:3.1.1 bluepic/processImage actions/Orchestrator.swift -t 300000
  
  echo -e "${GREEN}Install Complete${NC}"
  wsk list
}

function uninstall() {
  echo -e "${RED}Uninstalling..."
  
  echo "Removing legacy actions..."

  wsk action delete bluepic/prepareReadImage
  wsk action delete bluepic/prepareWeatherRequest
  wsk action delete bluepic/prepareCloudantWrite
  wsk action delete bluepic/processImageStub
  wsk action delete bluepic/httpGet
  
  wsk action delete bluepic/processRequestThroughCloudantWrite
  wsk action delete bluepic/processRequestToCloudantWrite
  wsk action delete bluepic/processRequestThroughAlchemy
  wsk action delete bluepic/processRequestThroughWeather
  wsk action delete bluepic/processRequestToWeather
  wsk action delete bluepic/processRequestThroughReadImage
  wsk action delete bluepic/processRequestToReadImage
  wsk action delete bluepic/processRequestThroughReadUser
  wsk action delete bluepic/processFinalWrite
  wsk action delete bluepic/processCallback
  wsk action delete bluepic/alchemy


  echo "Removing current actions..."
  wsk action delete bluepic/weather
  wsk action delete bluepic/visualRecognition
  wsk action delete bluepic/cloudantRead
  wsk action delete bluepic/cloudantWrite
  wsk action delete bluepic/processImage
  wsk action delete bluepic/kituraRequestAuth
  wsk action delete bluepic/kituraCallback
  
  wsk package delete bluepic
  
  echo -e "${GREEN}Uninstall Complete${NC}"
  wsk list
}

function showenv() {
  echo -e "${YELLOW}"
  echo CLOUDANT_username=$CLOUDANT_username
  echo CLOUDANT_password=$CLOUDANT_password
  echo CLOUDANT_host=$CLOUDANT_host
  echo CLOUDANT_db=$CLOUDANT_db
  echo VISUAL_key=$VISUAL_key
  echo WEATHER_username=$WEATHER_username
  echo WEATHER_password=$WEATHER_password
  echo -e "${NC}"
}

case "$1" in
"--install" )
install
;;
"--uninstall" )
uninstall
;;
"--update" )
update
;;
"--reinstall" )
uninstall
install
;;
"--env" )
showenv
;;
* )
usage
;;
esac