#!/bin/bash

YDATE=$(date -d "-1 days" +"%a %d/%m/%Y")
DATE="$(echo $YDATE|cut -d ' ' -f2)"
SERVICES=("subham")
DIR="/jenkins/workspace"

echo -e "DATE\tSERVICENAME\tNUMBEROFBUILD\tSPACEOCCUPIED" > /tmp/Jenkins_stat.txt
for SERVICE in ${SERVICES[@]}
do
NUM_OF_BUILD="$(find $DIR  -maxdepth 1 -mtime -1 |grep $SERVICE |grep -v tmp$|awk '{print $NF}'|wc -l)"
if [ "${NUM_OF_BUILD}" -ne "0" ];then
SPACE="$(find $DIR  -maxdepth 1 -mtime -1 |grep $SERVICE |grep -v tmp$|awk '{print $NF}'|xargs du -sh|awk '{print $1}'|sed 's|M||g'|paste -sd+|bc)MB"
echo -e "${DATE}\t${SERVICE}\t${NUM_OF_BUILD}\t${SPACE}"
fi
done >> /tmp/Jenkins_stat.txt

[ -f /tmp/Jenkins_stat.txt ] && cat /tmp/Jenkins_stat.txt |column -t > /tmp/jenkins_stat_main.txt && rm -f /tmp/Jenkins_stat.txt
