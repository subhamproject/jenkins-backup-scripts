#!/bin/bash
#Script to take full backup of jenkins and its configuration and push the backup to S3"

if [ -z "${1}" ]
then
echo "Usage: $0 <jenkins_home_dir>"
exit
fi

BACKUP_DIR="/jenkins_backup"
JENKINS_HOME="${1}"
[ ! -d $BACKUP_DIR ] && mkdir -p $BACKUP_DIR
NOW="$(date +%d%m%Y-%H%M)"
BACKUP_NAME="jenkins-backup-$NOW.tgz"
BUCKET="reactorcx-jenkins-backup"

jenkins_backup () {
cd ${JENKINS_HOME}
tar --exclude='./workspace' -zcf ${BACKUP_DIR}/${BACKUP_NAME} . >> /dev/null
cd - >> /dev/null
}

push_to_S3 (){
[ -s ${BACKUP_DIR}/${BACKUP_NAME} ] && aws s3 cp ${BACKUP_DIR}/${BACKUP_NAME} s3://${BUCKET}/
}

jenkins_backup
push_to_S3
rm -rf ${BACKUP_DIR}/${BACKUP_NAME}
