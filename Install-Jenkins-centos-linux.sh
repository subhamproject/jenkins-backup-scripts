#!/bin/bash

[ ! -f /etc/yum.repos.d/jenkins.repo ]  && wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo && rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key

[ -z "$(pidof -s java)" ] && [ -z "$(rpm -qa|grep java)" ] && yum install java -y || echo "Java jdk already installed,Skipping installation!"
[ -z "$(rpm -qa|grep jenkins)" ] && yum install jenkins -y || echo "Jenkins already installed,Skipping installation!"
[ -z "$(which git)" ] && yum install git -y || echo "Git already installed"
[ -n "$(rpm -qa|grep jenkins)" ] && [ -z "$(pidof -s java)" ] && chkconfig jenkins on && service jenkins start || echo "Jenkins service already running!"
