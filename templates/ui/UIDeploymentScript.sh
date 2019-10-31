#!/bin/bash
# Install UI Stack to Kubernetes Cluster

#inset variables in linux bastion shell
IN_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`

EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`

EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"

aws ssm get-parameter --region $EC2_REGION --name "EFSId"

efs_id=$(aws ssm get-parameters --name "EFSId" --region $EC2_REGION --query "Parameters[0].Value")

efs_id=${efs_id//\"/}

ELKdomain=$(aws ssm get-parameters --name "ELKDomain" --region $EC2_REGION --query "Parameters[0].Value")
ELKdomain=${ELKdomain//\"/}

#create efs mount directory
sudo mkdir -p /mnt/efs
sudo chmod 777 /mnt/efs

## Get S3 Bucket ##
QSS3BucketName=$(aws ssm get-parameters --name "QSS3BucketName" --region $EC2_REGION --query "Parameters[0].Value")
QSS3KeyPrefix=$(aws ssm get-parameters --name "QSS3KeyPrefix" --region $EC2_REGION --query "Parameters[0].Value")
QSS3KeyPrefix=${QSS3KeyPrefix//\"/}
QSS3BucketName=${QSS3BucketName//\"/}
S3SyncURL=s3://${QSS3BucketName}/${QSS3KeyPrefix}deployments
cd /exec-ui
aws s3 sync ${S3SyncURL} .

sleep 5

#change EFS dns name and region
sed -i  "s|--fs--|$efs_id|"  /exec-ui/efs/efs-deployment.yaml
sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/efs/efs-deployment.yaml

#change IBA dns name and region
sed -i  "s|--fs--|$efs_id|"  /exec-ui/iba/iba-deployment.yaml

sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/iba/iba-deployment.yaml

#change Userinfo dns name and region
sed -i  "s|--fs--|$efs_id|"   /exec-ui/userinfo/userinfo-deployment.yaml

sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/userinfo/userinfo-deployment.yaml

sed -i  "s|--instance_name--|$instance_name|"  /exec-ui/userinfo/userinfo-cm-sqlserver.yaml

#change Nginx dns name and region
sed -i  "s|--fs--|$efs_id|"  /exec-ui/nginx/nginx-deployment.yaml

sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/nginx/nginx-deployment.yaml

#change converter
sed -i  "s|--fs--|$efs_id|"  /exec-ui/converter/converter-deployment.yaml

sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/converter/converter-deployment.yaml

sed -i  "s|--sql--|$sqlip|"  /exec-ui/converter/converter-cm-sql.yaml



#mount the efs on the bastion node
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $efs_id.efs.$EC2_REGION.amazonaws.com:/ /mnt/efs

sleep 5

# run efs script to make directories and copy driver files in to EFS
sudo chmod +x /exec-ui/efs/efs-script.sh
sh -xx /exec-ui/efs/efs-script.sh



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

#change the appconfig for notification using Mongo
sed -i  "s|--mongoprimaryip--|$mongoprimaryip|"  /exec-ui/notification/notification-cm.yaml
sed -i  "s|--mongosecondaryip0--|$mongosecondaryip0|"  /exec-ui/notification/notification-cm.yaml
sed -i  "s|--mongosecondaryip1--|$mongosecondaryip1|"  /exec-ui/notification/notification-cm.yaml


#change the appconfig for configurator-api using Mongo
sed -i  "s|--mongoprimaryip--|$mongoprimaryip|"  /exec-ui/configurator-api/configurator-api-cm.yaml
sed -i  "s|--mongosecondaryip0--|$mongosecondaryip0|"  /exec-ui/configurator-api/configurator-api-cm.yaml
sed -i  "s|--mongosecondaryip1--|$mongosecondaryip1|"  /exec-ui/configurator-api/configurator-api-cm.yaml

#change the appconfig for userinfo using Mongo
sed -i  "s|--mongoprimaryip--|$mongoprimaryip|"  /exec-ui/userinfo/userinfo-cm-mongodb.yaml
sed -i  "s|--mongosecondaryip0--|$mongosecondaryip0|"  /exec-ui/userinfo/userinfo-cm-mongodb.yaml
sed -i  "s|--mongosecondaryip1--|$mongosecondaryip1|"  /exec-ui/userinfo/userinfo-cm-mongodb.yaml


# get RDS endpoint ip
sqlip=$(aws ssm get-parameters --name "SQLDatabaseJdbcURL" --region $EC2_REGION --query "Parameters[0].Value")

sqlip=${sqlip//\"/}

instance_name=`echo $sqlip | awk -F. '{print $1}'`

# change appconfig for IBA to use RDS SQL
sed -i  "s|--sqlip--|$sqlip|"  /exec-ui/iba/iba-cm-soluminag8-sql.yaml
sed -i  "s|--instance_name--|$instance_name|"  /exec-ui/iba/iba-cm-soluminag8-sql.yaml

# change appconfig for Userinfo to use RDS SQL
sed -i  "s|--sqlip--|$sqlip|"  /exec-ui/userinfo/userinfo-cm-sqlserver.yaml




#change Placeholders for Logstash Component Lot
sed -i  "s|--es--|$ELKdomain|"  /exec-ui/logstash/logstash-componentlot-cm-sql.yaml
sed -i  "s|--fs--|$efs_id|"  /exec-ui/logstash/logstash-componentlot-deployment.yaml
sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/logstash/logstash-componentlot-cm-sql.yaml
sed -i  "s|--sqlip--|$sqlip|"  /exec-ui/logstash/logstash-componentlot-cm-sql.yaml
sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/logstash/logstash-componentlot-deployment.yaml

#change Placeholders for Logstash Component Part
sed -i  "s|--es--|$ELKdomain|"  /exec-ui/logstash/logstash-componentpart-cm-sql.yaml
sed -i  "s|--sqlip--|$sqlip|"  /exec-ui/logstash/logstash-componentpart-cm-sql.yaml
sed -i  "s|--fs--|$efs_id|"  /exec-ui/logstash/logstash-componentpart-deployment.yaml
sed -i  "s|--sqlip--|$sqlip|"  /exec-ui/logstash/logstash-componentpart-deployment.yaml
sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/logstash/logstash-componentpart-deployment.yaml

#change Placeholders for Logstash Component Serial
sed -i  "s|--es--|$ELKdomain|"  /exec-ui/logstash/logstash-componentserial-deployment.yaml
sed -i  "s|--fs--|$efs_id|"  /exec-ui/logstash/logstash-componentserial-deployment.yaml
sed -i  "s|--sqlip--|$sqlip|"  /exec-ui/logstash/logstash-componentserial-cm-sql.yaml
sed -i  "s|--es--|$ELKdomain|"  /exec-ui/logstash/logstash-componentserial-cm-sql.yaml
sed -i  "s|--region--|$EC2_REGION|"   /exec-ui/logstash/logstash-componentserial-deployment.yaml


#change Placeholders for Logstash Lot
sed -i  "s|--es--|$ELKdomain|"  /exec-ui/logstash/logstash-lot-cm-sql.yaml
sed -i  "s|--sqlip--|$sqlip|"  /exec-ui/logstash/logstash-lot-cm-sql.yaml
sed -i  "s|--fs--|$efs_id|"  /exec-ui/logstash/logstash-lot-deployment.yaml
sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/logstash/logstash-lot-deployment.yaml


#change Placeholders for Logstash Component Order
sed -i  "s|--es--|$ELKdomain|"  /exec-ui/logstash/logstash-order-cm-sql.yaml
sed -i  "s|--sqlip--|$sqlip|"  /exec-ui/logstash/logstash-order-cm-sql.yaml
sed -i  "s|--fs--|$efs_id|"   /exec-ui/logstash/logstash-order-deployment.yaml
sed -i  "s|--region--|$EC2_REGION|"   /exec-ui/logstash/logstash-order-deployment.yaml


#change Placeholders for Logstash  Serial
sed -i  "s|--es--|$ELKdomain|"  /exec-ui/logstash/logstash-serial-cm-sql.yaml
sed -i  "s|--sqlip--|$sqlip|"  /exec-ui/logstash/logstash-serial-cm-sql.yaml
sed -i  "s|--fs--|$efs_id|"  /exec-ui/logstash/logstash-serial-deployment.yaml
sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/logstash/logstash-serial-deployment.yaml


#change Placeholders for Logstash User
sed -i  "s|--es--|$ELKdomain|"  /exec-ui/logstash/logstash-user-cm-sql.yaml
sed -i  "s|--sqlip--|$sqlip|"  /exec-ui/logstash/logstash-user-cm-sql.yaml
sed -i  "s|--fs--|$efs_id|"  /exec-ui/logstash/logstash-user-deployment.yaml
sed -i  "s|--region--|$EC2_REGION|"  /exec-ui/logstash/logstash-user-deployment.yaml

## Loop through the sqlserver files to replace place holder - Note: Rest should be done like this rather than writing one sed per file##
for file in `find /exec-ui/logstash/ -type f -name "*.yaml" | grep sql`;
do
	sed -i "s|--instance_name--|$instance_name|g" $file
done
##

sleep 15

#speen Nginx before the stack to get ELB up and running
kubectl create -f /exec-ui/nginx

#give nginx enough time to get ELB address
sleep 30


#get nginx ELB address ento ELB variable
ELB=$(kubectl get svc nginx -o yaml | grep hostname | sed  "s/ //g" |  sed  "s/-hostname//g" | sed  "s/://g")
sleep 1


#change Nginx ELB with UI appconfig Placeholders
sed -i  "s|--ELB--|$ELB|"  /exec-ui/supervisor/supervisor-cm.yaml
sed -i  "s|--ELB--|$ELB|"  /exec-ui/configurator/configurator-cm.yaml
sed -i  "s|--ELB--|$ELB|"  /exec-ui/notification/notification-cm.yaml
sed -i  "s|--ELB--|$ELB|"  /exec-ui/operations/operation-cm.yaml
sed -i  "s|--ELB--|$ELB|"  /exec-ui//login/login-cm.yaml

sleep 1

#create directory for Doc Converter
mkdir -p /mnt/efs/converter/logs

#run UI-stack
sh /exec-ui/kube-start.sh
sleep 30

# Get Solumina Endpoint URL
SoluminaEndpoint=$(kubectl get svc | grep nginx | awk '{ print $4 }')
aws ssm put-parameter --name SoluminaEndpoint --value $SoluminaEndpoint --type "String" --region $EC2_REGION --overwrite

# some cleanup #
aws ssm delete-parameter --name UIWaitHandle --region $EC2_REGION
aws ssm delete-parameter --name PostRDSStackName --region $EC2_REGION
aws ssm delete-parameter --name QSS3BucketName --region $EC2_REGION
aws ssm delete-parameter --name QSS3KeyPrefix --region $EC2_REGION
aws ssm delete-parameter --name JDBCDriverBucketName --region $EC2_REGION
aws ssm delete-parameter --name JDBCDriverKeyPrefix --region $EC2_REGION
