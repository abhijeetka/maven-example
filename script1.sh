#!/bin/bash
echo -n "Detecting current project version number..."

MAVEN_BIN=`which mvn`
BRANCHNAME=$branchname
echo "${MAVEN_BIN}"
GIT_BIN=/usr/local/git/bin/git

MAVEN_HELP_PLUGIN="org.apache.maven.plugins:maven-help-plugin:2.1.1"

MAVEN_HELP_PLUGIN_EVALUATE_VERSION_GOAL="${MAVEN_HELP_PLUGIN}:evaluate -Dexpression=project.version"

CURRENT_VERSION=$($MAVEN_BIN help:evaluate -Dexpression=project.version | grep -v '\[.*')
MAJOR_VERSION=$(echo $CURRENT_VERSION | cut -d \- -f 1)
SUFFIX=$(echo $CURRENT_VERSION | cut -d \- -f 2)

echo "$CURRENT_VERSION $MAJOR_VERSION $SUFFIX"

NUMBER_OF_FIELDS=`echo "${CURRENT_VERSION}" | awk -F"-"  "{ print NF }"`

#echo $NUMBER_OF_FIELDS

if [ "$NUMBER_OF_FIELDS" -ne "2" ] &&  [ "$NUMBER_OF_FIELDS" -ne "3" ]
  then
    exit 1
else
    if [ "$SUFFIX" == "SNAPSHOT" ]
      then
        export NEW_VERSION="${MAJOR_VERSION}-STABLE"
    else
      if [ "$SUFFIX" == "STABLE" ]
      then
        export NEW_VERSION="${MAJOR_VERSION}-RELEASE"
      else 
        export NEW_VERSION="${MAJOR_VERSION}-${SUFFIX}"
      fi
    fi
fi

$MAVEN_BIN versions:set -DnewVersion=$NEW_VERSION

echo "New Version set"

#mvn clean package
