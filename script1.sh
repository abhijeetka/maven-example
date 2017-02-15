#!/bin/bash
echo -n "Detecting current project version number..."

MAVEN_BIN=`which mvn`
BRANCHNAME=`master`
echo "${MAVEN_BIN}"
GIT_BIN=`which git`

function validatePomExists() {
  CURRENT_DIRECTORY=`pwd`
  if [ -f pom.xml ] ; then
    echo "Found pom.xml file: [${CURRENT_DIRECTORY}/pom.xml]"
  else
    echo "ERROR: No pom.xml file detected in current directory [${CURRENT_DIRECTORY}]. Exiting script with error status."
    exit 50
  fi
}

# Function for validating pom.xml file
function validatePom() {
  `${MAVEN_BIN} validate`
  STATUS=`echo $?`
  if [ ${STATUS} -ne 0 ] ; then
    echo "ERROR: Maven POM did not validate successfully. Exiting script with error status."
    exit 40
  fi
}

MAVEN_HELP_PLUGIN="org.apache.maven.plugins:maven-help-plugin:2.1.1"

MAVEN_HELP_PLUGIN_EVALUATE_VERSION_GOAL="${MAVEN_HELP_PLUGIN}:evaluate -Dexpression=project.version"

# Validates if pom present or not
validatePomExists

CURRENT_VERSION=$($MAVEN_BIN help:evaluate -Dexpression=project.version | grep -v '\[.*')
# Validating POM File
if [ -z ${CURRENT_VERSION} ] ; then
    echo "  ERROR: Couldn't detect current version. Validating pom in case there was a validation issue."
    validatePom
    echo "  ERROR: Couldn't detect current version. Exiting with error status."
    exit 20
else
    echo "  Version found: [${CURRENT_VERSION}]"
fi

PREFIX=$(echo $CURRENT_VERSION | cut -d \- -s -f 1)
MAJOR_VERSION=$(echo $CURRENT_VERSION | cut -d \- -s -f 2)
SUFFIX=$(echo $CURRENT_VERSION | cut -d \- -s -f 3)

CURRENT_BUILD_NUMBER=`echo ${MAJOR_VERSION} | sed -e 's/[0-9]*\.//g'`
NEXT_BUILD_NUMBER=`expr ${CURRENT_BUILD_NUMBER} + 1`
echo " Next build number:$NEXT_BUILD_NUMBER";
echo "Current Version: $CURRENT_VERSION $PREFIX $MAJOR_VERSION $SUFFIX"
echo "${CURRENT_VERSION}" | awk -F"-"  "{ print NF }"

NUMBER_OF_FIELDS=`echo "${CURRENT_VERSION}" | awk -F"-"  "{ print NF }"`

if [ "$NUMBER_OF_FIELDS" -ne "2" ] &&  [ "$NUMBER_OF_FIELDS" -ne "3" ]
  then
    exit 1
else
    if [ "$SUFFIX" == "SNAPSHOT" ]
      then
        export NEW_VERSION="${PREFIX}-${MAJOR_VERSION}-STABLE"
	#Now we need to create a development version also.
	#NEW_MAJOR_VERSION = `expr ${MAJOR_VERSION} + 1`
	#NEW_DEV_VERSION =`${PREFIX}-${NEW_MAJOR_VERSION}-${SUFFIX}`
    else
      if [ "$SUFFIX" == "STABLE" ]
      then
        export NEW_VERSION="${PREFIX}-${MAJOR_VERSION}-RELEASE"
      else 
        export NEW_VERSION="${PREFIX}-${MAJOR_VERSION}-${SUFFIX}"
      fi
    fi
fi

$MAVEN_BIN versions:set -DnewVersion=$NEW_VERSION

echo "New Version set $NEW_VERSION"

# Creating new branch for Stable Version
ADD=`${GIT_BIN} add -u .`
COMMIT=`${GIT_BIN} commit -a -m "updated pom version to ${NEW_VERSION}"`
PUSH=`${GIT_BIN} push abhi ${branchname}:${NEW_VERSION}`



