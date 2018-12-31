#!/bin/bash
#Script to take full backup of jenkins and its configuration and push the backup to S3"

RECIPIENTS="subham.rhce@gmail.com"
BACKUP_DIR="/jenkins_backup"
JENKINS_HOME="$(cat /etc/sysconfig/jenkins|grep ^JENKINS_HOME|cut -d '=' -f2|sed 's|"||g')"
[ ! -d ${BACKUP_DIR} ] && mkdir -p ${BACKUP_DIR}
NOW="$(date +%d%m%Y-%H%M)"
BACKUP_NAME="jenkins-backup-${NOW}.tar.xz"
BUCKET="test-jenkins-backup"

jenkins_backup () {
[ "$(ps -ef|grep JENKINS_HOME|grep -v grep|wc -l)" -ge "1" ] && service jenkins stop && sleep 5
[ "$(ps -ef|grep nginx|grep -v grep|wc -l)" -ge "1" ] && service nginx stop
cd ${JENKINS_HOME}
tar --exclude='./workspace' -czf - . | xz -1 -c -T 0 - > ${BACKUP_DIR}/${BACKUP_NAME}
cd - >> /dev/null
}

push_to_S3 (){
for FILE in $(find ${BACKUP_DIR} -maxdepth 1 -type f -name *.tar.xz)
do
[ -s ${FILE} ] && aws s3 cp ${FILE} s3://${BUCKET}/
done
[ $? -eq 0 ] && echo "Jenkins backup successfully taken and pushed to S3" |mailx -s "Jenkins Backup Status"  -S "from=subham@gmail.com" "${RECIPIENTS}" || echo "Jenkins backup was not successfull,Please check" |mailx -s "Jenkins Backup Status"  -S "from=subham@gmail.com" "${RECIPIENTS}"
}

PS3='Please enter your choice: '
options=("Jenkins Full Backup" "Push Backup To S3" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Jenkins Full Backup")
            jenkins_backup
            ;;
        "Push Backup To S3")
            push_to_S3
            find ${BACKUP_DIR} -maxdepth 1 -type f -name *.tar.xz -exec rm -rf {} \;
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
