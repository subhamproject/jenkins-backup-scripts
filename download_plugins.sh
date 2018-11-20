#!/bin/bash

plugin_repo_url="http://updates.jenkins-ci.org/download/plugins"
plugin_dir="/tmp/plugins"
[ ! -d $plugin_dir ] && mkdir -p $plugin_dir

for PLUGINS in `cat /tmp/file.txt`
do
wget -P $plugin_dir $plugin_repo_url/$(echo $PLUGINS|cut -d':' -f1)/$(echo $PLUGINS|cut -d':' -f2)/$(echo $PLUGINS|cut -d':' -f1).hpi
done
