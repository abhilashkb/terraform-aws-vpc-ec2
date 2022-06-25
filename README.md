# Create Ec2 innstance on custom VPC using Terrafom

##Here are the steps to implement ec2 instance on AWS using terraform code

1.create a vpc

2.Create a internet gateway

3.create custom Route table

4.create a subnet

5.associate subnet with route table

6.create SG to allow port 22,80,443

7.create a network interface with an ip in that was created in step4

8.Assign elastic ip to the network interface

9.Add network gateway to routetable

10.Create ec2 instance 

11.Create key pair

12.Save private key to local file