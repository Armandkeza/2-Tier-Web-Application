# 2-Tier-Web-Application
Deploy high available Web App with AWS auto-scaling
the above terraform code deploys a 2 tier Web Application with the following:

1. Network
-VPC: 
-Public Subnets
-Private Subnets
-Internet Gateway
-NAT Gateway
-Service endpoint to connect privately to S3.
-Security Group

2.Compute
-Auto-scaling group
-Application Load balancer

3.Storage
-S3 bucket to host applications files

4.IAM
-IAM role which grants EC2 access to S3 storage


The application Load balancer resides in the public subnets in both AZ1 and AZ2 and is the entry point to Application. it has the target group as the auto-scaling group enables to ensure to always have enough capacity to handle the application load while being cost efficient.
the EC2 instance of the auto-scaling group resides on the Private subnet and are not exposed to the internet.
A NAT Gateway is deployed in each availability zone to allow the outgoing traffic to the internet for the EC2 instance in the private subnet.
A S3 bucket is created to host application files.
An IAM role is defined and attached to the EC2 instances to be able to connect to S3 bucket to retrieve applications file at startup time. the connection between the EC2 instances and S3 bucket goes through the AWS Backbone network through the use of a service endpoint.
