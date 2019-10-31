# iba and userinfo driver 
sudo mkdir -p /mnt/efs/driver

#nginx logs
sudo mkdir -p /mnt/efs/nginx/logs


#logstash data directory
sudo mkdir -p /mnt/efs/logstash/data/componenct-part

sudo mkdir -p /mnt/efs/logstash/data/component-lot

sudo mkdir -p /mnt/efs/logstash/data/component-serial

sudo mkdir -p /mnt/efs/logstash/data/lot

sudo mkdir -p /mnt/efs/logstash/data/order

sudo mkdir -p /mnt/efs/logstash/data/serial

sudo mkdir -p /mnt/efs/logstash/data/user


#logstash logs directory
sudo mkdir -p /mnt/efs/logstash/logs/componenct-part

sudo mkdir -p /mnt/efs/logstash/logs/component-lot

sudo mkdir -p /mnt/efs/logstash/logs/component-serial

sudo mkdir -p /mnt/efs/logstash/logs/lot

sudo mkdir -p /mnt/efs/logstash/logs/order

sudo mkdir -p /mnt/efs/logstash/logs/serial

sudo mkdir -p /mnt/efs/logstash/logs/user


#change folder permision
sudo chmod -R 777 /mnt/efs
sudo chown -R ec2-user:ec2-user /mnt/efs

## Get S3 Bucket ##
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
JDBCDriverBucketName=$(aws ssm get-parameters --name "JDBCDriverBucketName" --region $EC2_REGION --query "Parameters[0].Value")
JDBCDriverKeyPrefix=$(aws ssm get-parameters --name "JDBCDriverKeyPrefix" --region $EC2_REGION --query "Parameters[0].Value")
JDBCDriverKeyPrefix=${JDBCDriverKeyPrefix//\"/}
JDBCDriverBucketName=${JDBCDriverBucketName//\"/}
S3SyncURL=s3://${JDBCDriverBucketName}/${JDBCDriverKeyPrefix}

#copy driver to efs
#aws s3 cp ${S3SyncURL}/driver/ojdbc8.jar  /mnt/efs/driver
aws s3 cp ${S3SyncURL}driver/sqljdbc4.jar /mnt/efs/driver


