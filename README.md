# servercfg

1. Setup security group for database

1. Setup RDS
 ```
aws rds create-db-instance --db-instance-identifier utilitydb --engine postgres --allocated-storage 5 --db-instance-class db.t2.micro --vpc-security-group-ids sg-a76aa8dd --availability-zone us-west-2a --db-subnet-group-name default-vpc-cbbb7bae --no-multi-az --no-publicly-accessible --storage-type gp2 --master-username dbuser --master-user-password <PASSWORD>
 ```

1. 

