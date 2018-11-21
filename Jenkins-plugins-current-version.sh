#!/bin/bash
JENKINS_HOME="${1:-/jenkins}"
PLUGIN_DIR="${JENKINS_HOME}/plugins"
DIR_LIST="$(ls -l $PLUGIN_DIR |grep ^d|awk '{print $NF}')"
echo "**********Plugin version details from `hostname`***********" > /tmp/Plugins_version_list_`hostname`.txt
for DIR in $DIR_LIST
do
if [ -d $PLUGIN_DIR/$DIR ]
then
VERSION=$(find $PLUGIN_DIR/$DIR -name pom.properties |xargs cat |grep version|cut -d'=' -f2)
echo "$DIR:$VERSION" >> /tmp/Plugins_version_list_`hostname`.txt
fi
done
