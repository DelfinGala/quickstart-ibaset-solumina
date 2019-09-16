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

#copy driver to efs
aws s3 cp s3://ibaset-cloudformation/deployments/driver/ojdbc8.jar  /mnt/efs/driver
aws s3 cp s3://ibaset-cloudformation/deployments/driver/sqljdbc4.jar /mnt/efs/driver

