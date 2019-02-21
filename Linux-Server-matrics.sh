#!/bin/bash
## Script to monitor Memory and Filesystem usage on Server

LIMIT=90
LOG_FILE="/tmp/disk_util.txt"
RECIPIENTS="devops@mos.com"


##Function to collect Memory metrics
MEMORY()
{
  DATE=`date +%c`
  MEM_USED=`free -m  | awk -F' ' '/Mem/{printf "%.0f\n", $3/$2*100}'`
  if [ "${MEM_USED}" -ge "${LIMIT}" ];then
     echo -e "Team,\nMemory utilization is currently \"$MEM_USED%\" on server \"$(hostname)\" as on \"${DATE}\"" |mailx -s "Alert: Memory Threshold Breached on $(hostname)" -S "from=smandal@gmail.com"  "${RECIPIENTS}"
 fi
}

## Function to collect Filesystem metrics
FILESYSTEM()
{
  df -Ph | grep -vE '^Filesystem|tmpfs|cdrom|boot|docker' | awk '{ print $5 " " $6 " " $1 }' | while read output;
  do
  USED=$(echo $output | awk -F' ' '{printf "%.0f\n", $1}' )
  partition=$(echo $output | awk '{ print $2 }' )
   if [ "${USED}" -ge "${LIMIT}" ]; then
     echo  "Following Partition Running out of space \"$partition ($USED%)\" on $(hostname) as on $(date)" >>  ${LOG_FILE}
   fi
  done
}

## Function to collect GC's
GC_COLLECTION()
{
  FILE_PATH="/var/log/jenkins"
  FILE="$(find ${FILE_PATH} -type f -name "gc-*" -ctime -5)"
  CHECKCOUNT=$(awk -v d1="$(date +%Y-%m-%dT%H:%M --date='5 min ago')" -v d2="$(date +%Y-%m-%dT%H:%M)" '$0 > d1 && $0 < d2 || $0 ~ d2' ${FILE} | grep -ci "Full GC")
   if [ $CHECKCOUNT -gt 20 ]
   then
  echo "$CHECKCOUNT occurrences of the \"Full GC\" has been found in the last 5 minutes"| mailx -s "Alert: High GC on $(hostname)" -S "from=smandal@gmail.com"  "${RECIPIENTS}"
   fi
}

## Calling all functions
GC_COLLECTION
MEMORY
FILESYSTEM && [ -s "${LOG_FILE}" ] && mailx -s "Alert: Almost Out of Disk Space on $(hostname)" -S "from=smandal@gmail.com"  "${RECIPIENTS}" < ${LOG_FILE} && rm -rf ${LOG_FILE}
