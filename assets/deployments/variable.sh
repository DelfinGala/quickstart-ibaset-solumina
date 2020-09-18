#!/bin/bash

## Topology ##
##############

## Define APP nodes
MASTER_NODE="--MASTER_NODE--"
APP_NODE1="--APP_NODE 1--"
APP_NODE2="--APP_NODE 2--"
APP_NODE3="--APP_NODE 3--"
APP_NODE4="--APP_NODE 4--"
APP_NODE5="--APP_NODE 5--"
ELK_NODE1="--APP_NODE 6--"
ELK_NODE2="--APP_NODE 7--"
ELK_NODE3="--APP_NODE 9--"

## External configs ##
######################
## Define Database engine either "oracle" or "sqlserver"
DATABASE="--database engine--"

## FQDN (Fully Qualified Domain Name) of the Docker swarm manager node. For example: portal.mycompany.com
DNS_NAME="example.mycompany.com"

## The connection string from the application to the database.
## example for oracle: jdbc:oracle:thin:@HOSTNAME:1621:DATABASE
## example for Sqlserver: jdbc:sqlserver://HOSTNAME;applicationName=SoluminaFND;instanceName=DVLPTRNKSS;databaseName=Solumina;schemaName=SFMFG;sendStringParametersAsUnicode=false
CONN_STRING="--database connection string--"

## Database passwords for user "MT_CONPOOL_USER"
DB_PASSWORD="enter password"

## The Public IP address of Kubernetes Master node.
HOST_IP_ADDRESS="--K8s Master node IP Address--"

## The address to the ActiveMQ server, when used as the JMS provider or ESB.
## If you want to use dedicated ACTIVEMQ_ADDRESS, use like this. For example, "tcp://HOST-IP:61616"
## Keep default value as below if you want use enternal ActiveMQ
ACTIVEMQ_ADDRESS="vm://localhost"

## Define your mongodb root passwords, whatever you want.
MONGODB_ROOT_PASSWORD="define your mongodb root passwords"

## Check database timezone and then put value for DATABASE_TIMEZONE variable based on that.
## Ex. DATABASE_TIMEZONE=America/Los_Angeles
## For more details of timezone values, refer this :
## https://en.wikipedia.org/wiki/Time_zone
## https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
DATABASE_TIMEZONE="Timezone"

## Please put timezone same as database timezone.
## (For oracle only: )
## (Note : Put only abbreviation name. Offset value will not work.)
## Check below link for how many time-zones are supported. Choose from that list by comparing your database timezone abbreviation name or your database timezone offset value.
## https://docs.oracle.com/cd/B28359_01/olap.111/b28126/dml_functions_2036.htm#OLADM612 -> Table 8-1 Time Zones
ELK_TIMEZONE="abbreviation name(example- PST,PDT..etc)"
