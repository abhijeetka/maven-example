#!/bin/bash
echo -n "Detecting current project version number..."

MAVEN_BIN=`which mvn`
BRANCHNAME=$branchname
echo "${MAVEN_BIN}"
GIT_BIN=`which git`

git config --global user.email "abhijeet.kamble619@gmail.com"
git config --global user.name "Abhijeet"

echo "GIT ${GIT_BIN}"

MAVEN_HELP_PLUGIN="org.apache.maven.plugins:maven-help-plugin:2.1.1"

MAVEN_HELP_PLUGIN_EVALUATE_VERSION_GOAL="${MAVEN_HELP_PLUGIN}:evaluate -Dexpression=project.version"



function validatePomExists() {
  CURRENT_DIRECTORY=`pwd`
  if [ -f pom.xml ] ; then
    echo "Found pom.xml file: [${CURRENT_DIRECTORY}/pom.xml]"
  else
    echo "ERROR: No pom.xml file detected in current directory [${CURRENT_DIRECTORY}]. Exiting script with error status."
    exit 50
  fi
}

function validatePom() {
  `${MAVEN_BIN} validate`
  STATUS=`echo $?`
  if [ ${STATUS} -ne 0 ] ; then
    echo "ERROR: Maven POM did not validate successfully. Exiting script with error status."
    exit 40
  fi
}

validatePomExists

REVERT=`${MAVEN_BIN} versions:revert`

CURRENT_PROJECT_VERSION=`${MAVEN_BIN} ${MAVEN_HELP_PLUGIN_EVALUATE_VERSION_GOAL} | egrep '^[0-9\.]*(-[a-z])?(-SNAPSHOT)?$'`
  if [ -z ${CURRENT_PROJECT_VERSION} ] ; then
    echo "  ERROR: Couldn't detect current version. Validating pom in case there was a validation issue."
    validatePom
    echo "  ERROR: Couldn't detect current version. Exiting with error status."
    exit 20
  else
    echo "  Version found: [${CURRENT_PROJECT_VERSION}]"
  fi

 CLEANED=`echo ${CURRENT_PROJECT_VERSION} | sed -e 's/[^0-9][^0-9]*$//'`
 CURRENT_BUILD_NUMBER=`echo ${CLEANED} | sed -e 's/[0-9]*\.//g'`
 NEXT_BUILD_NUMBER=`expr ${CURRENT_BUILD_NUMBER} + 1`
 
  echo "Sanitized current project version: [${CLEANED}]"
  echo "Current build number in project version: [${CURRENT_BUILD_NUMBER}]"
  echo "Calculated next build number: [${NEXT_BUILD_NUMBER}]"
 
  if [ -z ${NEXT_PROJECT_VERSION} ] ; then
    NEXT_PROJECT_VERSION=`echo ${CLEANED} | sed -e "s/[0-9][0-9]*\([^0-9]*\)$/${NEXT_BUILD_NUMBER}/"`
  else
    echo "Version number was overridden on the command line. Using [${NEXT_PROJECT_VERSION}] to calculate next version."
    NEXT_PROJECT_VERSION="${NEXT_PROJECT_VERSION}"
  fi
 
  echo "Next project version: [${NEXT_PROJECT_VERSION}]"
  
#  echo "1.0.8-201505-SNAPSHOT" |  sed -e 's/[^0-9]*$//' |  sed -e 's/[0-9].[0-9]*-$//'
 # ITERATION=`echo "1.0.8-201505-SNAPSHOT" |  sed -e 's/[^0-9]*$//' |  cut -d\- -f2`
  
 # BRANCHVERSION=`echo "1.0.8" |  sed -e 's/.[0-9]*$//'`
 # echo "${BRANCHVERSION}-${ITERATION}"
 # `echo "head -4 doc/CHANGELOG.txt"`
 NEXTVERSION=`echo "${NEXT_BUILD_NUMBER}" | tr "0-9" "1-9"`
 NEWVERSION="${NEXT_PROJECT_VERSION}-SNAPSHOT"
  
 echo "New Version: ${NEWVERSION}"
 echo "Next Verson  ${NEXTVERSION}"

git config --global push.default matching
git config --global push.default simple


UPDATE=`${MAVEN_BIN} versions:set -DgenerateBackupPoms=false -DnewVersion=${CLEANED}`
DEPLOY=`${MAVEN_BIN} clean deploy -U`
COMMIT=`${GIT_BIN} commit -a -m "release ${CLEANED}"`
echo "commit done and doing tag";
TAGVER=`${GIT_BIN} tag ${CLEANED}`
echo " push code";


PUSHVER=`${GIT_BIN} push abhi ${CLEANED}`
echo " updating new version";
UPDATE=`$MAVEN_BIN versions:set -DnewVersion=${NEWVERSION}`
COMMIT=`${GIT_BIN} commit -a -m "updated pom version"`
PUSH=`${GIT_BIN} push abhi ${NEWVERSION}:${NEWVERSION}`

