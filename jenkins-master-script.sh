#!/bin/bash
#####################################################################################################################################################
########          MASTER SCRIPT TO DO FOLLOWING              ########################################################################################
######### 1 - 'Get current version of installed plugins'     ########################################################################################
######### 2 - 'Take backup of plugins we are going to upgrade'#######################################################################################
######### 3 - 'Upgrade list of plugins'                       #######################################################################################
#####################################################################################################################################################


JENKINS_HOME="$(cat /etc/sysconfig/jenkins|grep ^JENKINS_HOME|cut -d '=' -f2|sed 's|"||g')"
PLUGIN_DIR="${JENKINS_HOME}/plugins"
BACKUP_DIR="${JENKINS_HOME}/backup_$$_`date "+%Y-%m-%d"`"

echo "Please make sure Jenkins is not running in server before performing below action,Else it may get corrupted"
echo " "
### Function to get current plugins version installed in server #######
function current_plugins_version ()
{
       DIR_LIST="$(ls -l $PLUGIN_DIR |grep ^d|awk '{print $NF}')"
       echo "**********Plugin version details from `hostname`***********" > ${JENKINS_HOME}/Current_plugins_version_$$_list_`hostname`.txt
       for DIR in $DIR_LIST
       do
       if [ -d $PLUGIN_DIR/$DIR ]
       then
       #VERSION=$(find $PLUGIN_DIR/$DIR -name pom.properties |xargs cat |grep version|cut -d'=' -f2)
       VERSION=$(find $PLUGIN_DIR/$DIR -name MANIFEST.MF|xargs cat|grep "Plugin-Version: "|cut -d':' -f2|tr -d ' ')
       echo "$DIR:$VERSION" >> ${JENKINS_HOME}/Current_plugins_version_$$_list_`hostname`.txt
      fi
      done
      echo "Current plugin version details are taken..output can be found in ${JENKINS_HOME}/Current_plugins_version_$$_list_`hostname`.txt"
}

### Function to take backup of plugins which are to be upgraded in server #######
function backup_plugins ()
{
     [ ! -d $BACKUP_DIR ] && mkdir -p $BACKUP_DIR
     for PLUGINS_LIST in $(cat ${JENKINS_HOME}/Plugins_to_be_updated.txt) ## ${JENKINS_HOME}/Plugins_to_be_updated.txt is a file where plugins details need to be put in which are to be updated
     do
     [ -d $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1) ] && mv $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1) $BACKUP_DIR/
     [ -f $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).jpi ] && mv $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).jpi* $BACKUP_DIR/
     [ -f $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).jpi.tmp ] && mv $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).jpi.tmp $BACKUP_DIR/
     [ -f $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).hpi ] &&  mv $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).hpi* $BACKUP_DIR/
     [ -f $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).bak ] &&  mv $PLUGIN_DIR/$(echo $PLUGINS_LIST|cut -d':' -f1).bak $BACKUP_DIR/
    done
    echo "Backup for plugins which are to be upgrade has been taken in $BACKUP_DIR"
}

### Function to take install and upgrade plugins in server #######
function upgrade_plugins () {
    file_owner="jenkins:jenkins"
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

  for plugin in $(cat ${JENKINS_HOME}/Plugins_to_be_updated.txt) ## ${JENKINS_HOME}/Plugins_to_be_updated.txt is a file where plugins details need to be put in which are to be updated
  do
  Plugin_install "$plugin"
  done

  #for f in ${PLUGIN_DIR}/*.hpi ; do
  for f in $(find ${PLUGIN_DIR} -name "*.hpi" -type f -mtime 0) ; do
  echo "Installing dependencies for $f"
  deps=$( unzip -p ${f} META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' |cut -d';' -f1 )
  for plugin in $deps; do
  #Plugin_install "$plugin"
  echo "${plugin}" >> /tmp/depency_$$_file.txt
  done
  done
  cat /tmp/depency_$$_file.txt|sort -V >> /tmp/deps_$$_file.txt
  declare -A array
  while IFS=':' read key value
  do
  array[$key]=$value
  done < /tmp/deps_$$_file.txt
  for key in ${!array[@]}
  do
  echo $key:${array[$key]}
  done >> /tmp/deps_$$_higher_version.txt
  for plugins in $(cat /tmp/deps_$$_higher_version.txt|sort -V)
  do
  Plugin_install "$plugins"
  done
  echo "fixing permissions"
  chown -R ${file_owner} ${PLUGIN_DIR}
  echo "All plugins with dependency has been upgraded"
  echo "Please restart Jenkins for the change to take effect"
}


PS3='Please enter your choice: '
options=("Get Current Plugins Version" "Take Plugins Backup" "Update Plugins" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Get Current Plugins Version")
            current_plugins_version
            ;;
        "Take Plugins Backup")
            backup_plugins
            ;;
        "Update Plugins")
            upgrade_plugins
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
