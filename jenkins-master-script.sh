#!/bin/bash
JENKINS_HOME="/var/lib/jenkins"
PLUGIN_DIR="${JENKINS_HOME}/plugins"
BACKUP_DIR="${JENKINS_HOME}/backup_`date "+%Y-%m-%d"`"

echo "Please make sure Jenkins is not running in server before performing below action,Else it may get corrupted"
echo " "
### Function to get current plugins version installed in server #######
function current_plugins_version ()
{
       DIR_LIST="$(ls -l $PLUGIN_DIR |grep ^d|awk '{print $NF}')"
       echo "**********Plugin version details from `hostname`***********" > /tmp/Plugins_version_list_`hostname`.txt
       for DIR in $DIR_LIST
       do
       if [ -d $PLUGIN_DIR/$DIR ]
       then
       #VERSION=$(find $PLUGIN_DIR/$DIR -name pom.properties |xargs cat |grep version|cut -d'=' -f2)
       VERSION=$(find $PLUGIN_DIR/$DIR -name MANIFEST.MF|xargs cat|grep "Plugin-Version: "|cut -d':' -f2|tr -d ' ')
       echo "$DIR:$VERSION" >> /tmp/Plugins_version_list_`hostname`.txt
      fi
      done
      echo "Current plugin version details are taken..output can be found in /tmp/Plugins_version_list_`hostname`.txt"
}

### Function to take backup of plugins which are to be upgraded in server #######
function backup_plugins ()
{
     [ ! -d $BACKUP_DIR ] && mkdir -p $BACKUP_DIR
     for PLUGINS_LIST in $(cat /tmp/file.txt)
     do
     [ -d $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1) ] && mv $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1) $BACKUP_DIR/
     [ -f $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).jpi ] && mv $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).jpi $BACKUP_DIR/
     [ -f $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).jpi.tmp ] && mv $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).jpi.tmp $BACKUP_DIR/
     [ -f $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).hpi ] &&  mv $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).hpi $BACKUP_DIR/
     [ -f $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).bak ] &&  mv $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).bak $BACKUP_DIR/
    done
    echo "Backup for plugins which are to be upgrade has been taken in $BACKUP_DIR"
}

### Function to take install and upgrade plugins in server #######
function upgrade_plugins () {
    file_owner=jenkins.jenkins
    plugin_repo_url="http://updates.jenkins-ci.org/download/plugins"
    [ ! -d $PLUGIN_DIR ] && mkdir -p $PLUGIN_DIR

   Plugin_install()
   {
   if [ -f ${PLUGIN_DIR}/$(echo $1|cut -d':' -f1).hpi -o -f ${PLUGIN_DIR}/$(echo $1|cut -d':' -f1).jpi ]; then
   echo "Skipped: $1 (already installed)"
   else
   echo "Installing: $1"
   curl -L --silent --output ${PLUGIN_DIR}/$(echo $1|cut -d':' -f1).hpi  $plugin_repo_url/$(echo $1|cut -d':' -f1)/$(echo $1|cut -d':' -f2)/$(echo $1|cut -d':' -f1).hpi
   fi
   }

  for plugin in $(cat /tmp/file.txt)
  do
  Plugin_install "$plugin"
  done

  for f in ${PLUGIN_DIR}/*.hpi ; do
  echo "Installing dependencies for $f"
  deps=$( unzip -p ${f} META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' |cut -d';' -f1 )
  for plugin in $deps; do
  Plugin_install "$plugin"
  done
  done
  echo "fixing permissions"
  chown ${file_owner} ${PLUGIN_DIR} -R
  echo "All plugins with dependency has been upgraded"
  echo "Please restart Jenkins for the change to take effect"
}


PS3='Please enter your choice: '
options=("Get Current Plugins Version" "Take Plugins Backup" "Install Updated Plugins" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Get Current Plugins Version")
            current_plugins_version
            ;;
        "Take Plugins Backup")
            backup_plugins
            ;;
        "Install Updated Plugins")
            upgrade_plugins
            upgrade_plugins
            upgrade_plugins
            upgrade_plugins
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
