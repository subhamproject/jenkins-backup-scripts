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


==================================================================================================================================
#!/bin/bash

SERVICES=("subham")
DIR="/jenkins/workspace"

echo -e "SERVICE_NAME\tNUMBEROF_BUILDS\tSPACE_OCCUPIED" > /tmp/Jenkins_stat.txt
echo -e "------------\t----------------\t--------------" >> /tmp/Jenkins_stat.txt
for SERVICE in ${SERVICES[@]}
do
#find . -mtime 1 # find files modified between 24 and 48 hours ago
NUM_OF_BUILDS="$(find $DIR  -maxdepth 1 -mtime 1 |grep $SERVICE |grep -v tmp$|awk '{print $NF}'|wc -l)"
if [ "${NUM_OF_BUILDS}" -ne "0" ];then
   BUILDS="$(find $DIR  -maxdepth 1 -mtime 1 |grep $SERVICE |grep -v tmp$|awk '{print $NF}')"
   SPACE_TYPE="$(echo ${BUILDS}|xargs du -sh|awk '{print $1}'|awk '{print substr($0,length,1)}'|uniq)"
if [ "${SPACE_TYPE}" == "M" ];then
   SPACE="$(find $DIR  -maxdepth 1 -mtime 1 |grep $SERVICE |grep -v tmp$|awk '{print $NF}'|xargs du -sh|awk '{print $1}'|sed 's|M||g'|paste -sd+|bc)MB"
elif [ "${SPACE_TYPE}" == "G" ];then
    SPACE="$(find $DIR  -maxdepth 1 -mtime 1 |grep $SERVICE |grep -v tmp$|awk '{print $NF}'|xargs du -sh|awk '{print $1}'|sed 's|G||g'|paste -sd+|bc)GB"
elif [ "${SPACE_TYPE}" == "K" ];then
    SPACE="$(find $DIR  -maxdepth 1 -mtime 1 |grep $SERVICE |grep -v tmp$|awk '{print $NF}'|xargs du -sh|awk '{print $1}'|sed 's|K||g'|paste -sd+|bc)KB"
fi
echo -e "${SERVICE}\t${NUM_OF_BUILDS}\t${SPACE}"
fi
done >> /tmp/Jenkins_stat.txt

[ -f /tmp/Jenkins_stat.txt ] && cat /tmp/Jenkins_stat.txt |column -t > /tmp/jenkins_stat_main.txt && rm -f /tmp/Jenkins_stat.txt
