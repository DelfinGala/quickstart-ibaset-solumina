#!/bin/bash


### Variables

DB_PASSWORD=MT_CONPOOL_USER
DB_DRIVER=com.microsoft.sqlserver.jdbc.SQLServerDriver
VALIDATION_QUERY="select getdate()"
ACTIVATED_PROFILE="sqlserver"
ACTIVEMQ_ADDRESS="vm://localhost"
DATABASE_TIMEZONE="Timezone" # NEW TO FIGURE OUT
# aws rds describe-db-instances --region=us-east-2 --filter Timezone
# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_SQLServer.html#SQLServer.Concepts.General.TimeZone
ELK_TIMEZONE="PST--OR--PDT"

### Note: The following values are set later in the script
# CONN_STRING=
# DNS_URL=
# HOST_IP_ADDRESS=

### AWS Variables

IN_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
EFS_ID=$(aws ssm get-parameters --name "EFSId" --region $EC2_REGION --query "Parameters[0].Value")
EFS_ID=${EFS_ID//\"/}
ELKdomain=$(aws ssm get-parameters --name "ELKDomain" --region $EC2_REGION --query "Parameters[0].Value")
ELKdomain=${ELKdomain//\"/}

### Create efs Mount Directory
sudo mkdir -p /mnt/efs
sudo chmod 777 /mnt/efs

### Get S3 Bucket
QSS3BucketName=$(aws ssm get-parameters --name "QSS3BucketName" --region $EC2_REGION --query "Parameters[0].Value")
QSS3KeyPrefix=$(aws ssm get-parameters --name "QSS3KeyPrefix" --region $EC2_REGION --query "Parameters[0].Value")
QSS3KeyPrefix=${QSS3KeyPrefix//\"/}
QSS3BucketName=${QSS3BucketName//\"/}
S3SyncURL=s3://${QSS3BucketName}/${QSS3KeyPrefix}assets/deployments
cd /exec-ui
aws s3 sync ${S3SyncURL} .

sleep 5

### Mount EFS to Bastion Host
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $EFS_ID.efs.$EC2_REGION.amazonaws.com:/ /mnt/efs

sleep 5

# run efs script to make directories and copy driver files in to EFS
sudo chmod +x /exec-ui/efs/efs-script.sh
sh -xx /exec-ui/efs/efs-script.sh

### MongoDB Variables
# get the primary mongo ip
mongoprimaryip=$(aws ssm get-parameters --name "MongoPrimaryIP" --region $EC2_REGION --query "Parameters[0].Value")
mongoprimaryip=${mongoprimaryip//\"/}

sleep 1

# get the primary 0 mongo ip
mongosecondaryip0=$(aws ssm get-parameters --name "MongoSecondary0IP" --region $EC2_REGION --query "Parameters[0].Value")
mongosecondaryip0=${mongosecondaryip0//\"/}

sleep 1

# get the primary 1 mongo ip
mongosecondaryip1=$(aws ssm get-parameters --name "MongoSecondary1IP" --region $EC2_REGION --query "Parameters[0].Value")
mongosecondaryip1=${mongosecondaryip1//\"/}

sleep 1

# Get the password for the mongo #
MongoDBAdminPassword=$(aws ssm get-parameters --name "MongoDBAdminPassword" --region $EC2_REGION --query "Parameters[0].Value" --with-decryption)
MongoDBAdminPassword=${MongoDBAdminPassword//\"/}


## Added for mongo build installation ##
### MONGO PREP ###
# Mongo client #
echo '[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7Server/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc' \
	            | sudo tee /etc/yum.repos.d/mongodb-org-4.0.repo

sudo rpm --import https://www.mongodb.org/static/pgp/server-4.0.asc
sudo yum install -y mongodb-org-shell

aws s3 sync s3://aws-artifacts-ibaset/v2/templates/mongodb/ mongodb
unzip mongodb/G8R2i020_Mongodb_FI.zip -d mongodb/
cd mongodb
sed -i "s~MONGODB_ROOT_PASSWORD~${MongoDBAdminPassword}~g" create_db_users.mn
mongo admin --authenticationDatabase admin --host $mongoprimaryip --password $MongoDBAdminPassword < create_db_users.mn
cd G8R2i020_Mongodb_FI_RC
sed -i "s~<MONGODB_HOSTNAME>:30030~${mongoprimaryip}:27017~g" values.sh
chmod 777 master_mongo.sh
./master_mongo.sh
cd ../..
pwd
### Done deploying mongodb build ###

### Get RDS Endpoint IP
sqlip=$(aws ssm get-parameters --name "SQLDatabaseJdbcURL" --region $EC2_REGION --query "Parameters[0].Value")
sqlip=${sqlip//\"/}
instance_name=`echo $sqlip | awk -F. '{print $1}'`

CONN_STRING="jdbc:sqlserver://${sqlip};instanceName=${instance_name};applicationName=SoluminaFND;databaseName=Solumina;schemaName=SFMFG;sendStringParametersAsUnicode=false"

### Loop through the sqlserver files to replace place holder - Note: Rest should be done like this rather than writing one sed per file##
for file in `find /exec-ui/logstash/ -type f -name "*.yaml" | grep sql`;
do
	sed -i "s|--instance_name--|$instance_name|g" $file
done
sleep 15

# ### Deploy Traefik
# helm repo add traefik https://containous.github.io/traefik-helm-chart
# helm repo update
# helm install traefik -f /exec-ui/helm/traefik-values.yaml traefik/traefik

### Wait for LoadBalancer Pending State
# sleep 30

# DNS_NAME=$(kubectl get svc traefik -n kube-system | awk 'NR>1 {print $4}')
# sleep 1

DNS_NAME=$(aws ssm get-parameters --name "SoluminaWebURL" --query "Parameters[0].Value" --region $EC2_REGION | sed 's/"//g')
echo "DNS_NAME from Route53 is $DNS_NAME"
### https to http
cd /exec-ui

for dir in `ls | grep -v logs |grep -v mongodb |grep -v elk |grep -v helm |grep -v iba |grep -v userinfo |grep -v search |grep -v k8s |grep -v traefik |grep -v cron |grep -v to-http |grep -v driver |grep -v customJRE11 |grep -v data |grep -v converter`;

do
        for file in `find $dir  -type f`;
        do
                sed -i "s~https://~http://~g" $file
        done
done

### Replace Placeholders

for dir in .;
do
	for file in `find $dir  -type f \( -iname "*" ! -iname "UIDeploymentScript.sh" \)`;
	do
	    # LoadBalancer
		sed -i "s~--DNS_NAME--~${DNS_NAME}~g" $file
		# Database
		sed -i "s~ACTIVATED_PROFILE_FOR_DATABASE~${ACTIVATED_PROFILE}~g" $file
		sed -i "s~--DB_DRIVER--~${DB_DRIVER}~g" $file
		sed -i "s~--DB_PASSWORD--~${DB_PASSWORD}~g" $file
		sed -i "s~--DB_TIMEZONE--~${DATABASE_TIMEZONE}~g" $file
		sed -i "s~VALIDATION_QUERY~${VALIDATION_QUERY}~g" $file
		sed -i "s~CONN_STRING~${CONN_STRING}~g" $file
		# EFS
		sed -i "s~CONN_STRING~${CONN_STRING}~g" $file
		sed -i  "s~--fs--~${EFS_ID}~g" $file
		sed -i  "s~--region--~${EC2_REGION}~g" $file
		# MongoDB
		sed -i "s~--mongoprimaryip--~${mongoprimaryip}~g" $file
		sed -i "s~--mongosecondaryip0--~${mongosecondaryip0}~g" $file
		sed -i "s~--mongosecondaryip1--~${mongosecondaryip1}~g" $file
		sed -i "s~--MongoDBAdminPassword--~${MongoDBAdminPassword}~g" $file
		# ELK
		sed -i "s~--es--~${ELKdomain}~g" $file
		# misc
		sed -i "s~ZIPKIN_URL~${ZIPKIN_URL}~g" $file
		sed -i "s~ACTIVEMQ_ADDRESS~${ACTIVEMQ_ADDRESS}~g" $file
		sed -i "s~--ELK_TIMEZONE--~${ELK_TIMEZONE}~g" $file
		sed -i "s~value: /usr/local/openjdk-11~value: ${JRE11_HOME}~g" $file
		sed -i "s~value: /opt/config/containerJRE~value: ${JRE11_HOME}~g" $file
	done
done

cd -

### Create Logs Directories and Copy Traefik Rules/Certs

mkdir -p /mnt/efs/logs/{converter,cron,iba,logstash,search,traefik,userinfo}
mkdir -p /mnt/efs/traefik/{extensions,traefikcert}
sudo cp -r /exec-ui/extensions/oob.toml /mnt/efs/traefik/extensions/
sudo cp -r /exec-ui/traefikcert/* /mnt/efs/traefik/traefikcert/
sudo chmod -R 777 /mnt/efs/logs

### Label Nodes
for node in $(kubectl get nodes | awk 'NR>1 { print $1}'); do kubectl label node $node app=app --overwrite; done
for node in $(kubectl get nodes | awk 'NR>1 {print $1}'); do kubectl label node $node datanode=elasticsearch; done

### run UI-stack
sh /exec-ui/kube-start.sh
sleep 60

### Dhruvit's snippet - Load Balancer - Route53 Automation###
## Get load balancer end point ##
LBENDPOINT=$(kubectl get svc traefik-ingress-service -n kube-system | awk 'NR>1 {print $4}')
until [ ! -z "$LBENDPOINT" ]
do  
	echo "Load Balancer is not ready yet, waiting 10 seconds more for a retry"
	sleep 10
	LBENDPOINT=$(kubectl get svc traefik-ingress-service -n kube-system | awk 'NR>1 {print $4}')    
done
echo "Load Balancer end point is $LBENDPOINT"
aws ssm put-parameter --name LBENDPOINT --value ${LBENDPOINT} --type String --region $EC2_REGION --overwrite

## Get some more details on Load Balancer###
LB_NAME=$(echo $LBENDPOINT | awk -F- '{ print $1 }')
echo "Load Balancer name is $LB_NAME"

LBHOSTEDZONE=$(aws elb describe-load-balancers --load-balancer-names "$LB_NAME" --query "LoadBalancerDescriptions[0].CanonicalHostedZoneNameID" --region $EC2_REGION aws elb describe-load-balancers --load-balancer-names "$LB_NAME" --query "LoadBalancerDescriptions[0].CanonicalHostedZoneNameID" --region $EC2_REGION | sed 's/"//g')
echo "Load Balancer Hosted Zone is $LB_HOSTED_ZONE "

aws ssm put-parameter --name LBHOSTEDZONE --value ${LBHOSTEDZONE} --type String --region $EC2_REGION --overwrite

sleep 10
## Send a response to LB wait condition ##
LBWaitHandle=$(aws ssm get-parameters --name "LBWaitHandle" --query "Parameters[0].Value" --region $EC2_REGION | sed 's/"//g')
curl -vvv -X PUT -H 'Content-Type:' --data-binary '{"Status" : "SUCCESS","Reason" : "Configuration Complete","UniqueId" : "ID5678","Data" : "Application has completed configuration."}' "${LBWaitHandle}"
###

## some cleanup #
aws ssm delete-parameter --name UIWaitHandle --region $EC2_REGION
aws ssm delete-parameter --name PostRDSStackName --region $EC2_REGION
aws ssm delete-parameter --name JDBCDriverBucketName --region $EC2_REGION
aws ssm delete-parameter --name JDBCDriverKeyPrefix --region $EC2_REGION
aws ssm delete-parameter --name MongoDBAdminPassword --region $EC2_REGION
aws ssm delete-parameter --name SSDBAdminPassword --region $EC2_REGION
aws ssm delete-parameter --name QSS3BucketName --region $EC2_REGION
aws ssm delete-parameter --name QSS3KeyPrefix --region $EC2_REGION
