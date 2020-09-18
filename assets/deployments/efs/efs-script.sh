### iba and userinfo Driver

sudo mkdir -p /mnt/efs/driver
sudo mkdir -p /mnt/efs/customJRE11-driver
sudo mkdir -p /mnt/efs/doc-converter-driver

# Creating logstash logs and data Directories

sudo mkdir -p /mnt/efs/logstash/logs/{component-{lot,part,serial}-sqlserver,discrepancy-sqlserver,discrepancy-user-sqlserver,disposition-sqlserver,logstash-{lot,order,serial,user}-sqlserver,rejected-{lot,serial}-sqlserver,rejected-component-{lot,part,serial}-sqlserver}
sudo mkdir -p /mnt/efs/logstash/data/{component-{lot,part,serial}-sqlserver,discrepancy-sqlserver,discrepancy-user-sqlserver,disposition-sqlserver,logstash-{lot,order,serial,user}-sqlserver,rejected-{lot,serial}-sqlserver,rejected-component-{lot,part,serial}-sqlserver}

# Change Permissions

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
# aws s3 cp ${S3SyncURL}driver/sqljdbc4.jar /mnt/efs/driver
aws s3 cp ${S3SyncURL}driver/mssql-jdbc-7.4.1.jre11.jar /mnt/efs/driver
aws s3 cp ${S3SyncURL}doc-converter-driver/mssql-jdbc-7.4.1.jre8.jar /mnt/efs/doc-converter-driver
sudo chmod -R 777 /mnt/efs/driver
sudo chmod -R 777 /mnt/efs/doc-converter-driver