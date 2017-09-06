#!/bin/sh

#--------------------------------------------------------#
# @Author:       Nipur Patodi                            #
# @Date:         06/09/2017                              #
# @Description:  This Script is to restart all demoens.  #
#--------------------------------------------------------#

TOMCAT_HOME="/home/ubuntu/apache-tomcat-8.5.20"
SPARK_HOME="/home/ubuntu/software/spark"
KAFKA_HOME="/home/ubuntu/software/kafka"
WEB_CODE="/home/ubuntu/code/web"
BE_CODE="/home/ubuntu/code/be"
IP="localhost"

#Copying web app file to web app directory
#Starting tomcat
cp ${WEB_CODE}/*.war ${TOMCAT_HOME}/webapp
${TOMCAT_HOME}/bin/startup.sh

#Starting zookeeper and kafka
nohup ${KAFKA_HOME}/bin/zookeeper-server-start.sh  ${KAFKA_HOME}/config/zookeeper.properties >log/zookeeper.log &
nohup ${KAFKA_HOME}/bin/kafka-server-start.sh  ${KAFKA_HOME}/config/server.properties >log/kafka.log &

#Starting spark
mkdir -p /tmp/spark-event
${SPARK_HOME}/sbin/start-master.sh
${SPARK_HOME}/sbin/start-slave.sh spark://${IP}:7077

#Submitting Streaming job

nohup ${SPARK_HOME}/bin/spark-submit --class org.dreambig.aad.xpression.Main --master spark://$IP:7077  --executor-memory 5G --total-executor-cores 3  ${BE_CODE}/Iexpress-all-1.0-SNAPSHOT.jar >log/be.log &
