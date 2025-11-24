# TechCorp AWS Infrastructure (Terraform) Deployment

## Overview
This project deploys a complete  web application infrastructure, which is highly available across multiple zones on AWS using Terraform. It includes a VPC, public and private subnets, Internet Gateway, NAT Gateways, Application Load Balancer (ALB), Bastion Host, Web Servers (behind ALB), and a Database Server.

## Architecture Overview

The infrastructure provisions:

- VPC with CIDR block 10.0.0.0/16

- Public Subnets for Bastion and ALB

- Private Subnets for Web Servers and DB

- Internet Gateway (public traffic)

- NAT Gateways (private subnet internet access)

- Security Groups for Bastion, ALB, Web Servers, and DB

- Application Load Balancer with health checks

- EC2 Instances:

  - Bastion host (public)

  - Web servers running Apache (private)
  
  - Database server (private)

- User-data scripts automatically configure Postgres, Apache, etc.



## Prerequisites
Before deploying this infrastructure, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Terraform** installed (version 1.0 or later)


## Project Structure


```
terraform-assessment/
├── main.tf                      
├── variables.tf                 
├── outputs.tf                   
├── terraform.tfvars.example     
├── user_data/
│   ├── web_server_setup.sh     
│   └── db_server_setup.sh      
├── evidence/
├──backend_s3                
└── README.md                    
```
 **Note**: 
    - evidence holds screenshots of provissioned resources
    - backend_s3 remote state manegement folder

## Setup Instructions

### Clone the repository

```bash
git clone
```
### Update Variable
- Copy the `terraform.tfvars.example` file to `terraform.tfvars`

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
- Edit `terraform.tfvars` with your values:

 ```hcl
    aws_region        = ""

    bastio_server_instance_type = ""
    db_server_instance_type     = ""
    web_server_instance_type    = ""
    key_pair_name               = ""
    my_ip_address               = "Your IP Address/32"
    my_profile                  = ""

   ```

### Initialize Terraform
```bash
terraform init
```

### Review the Deployment Plan
```bash
terraform plan
```

### Step 5: Deploy the Infrastructure
```bash
terraform apply
```
Type `yes` when prompted to confirm the deployment.

⏱️ **Expected to take some minutes **

### Output 
 - The following will be displayed
    - VPC ID
    - Load Balancer DNS name
    - Bastion public IP


## Accessing the Infrastructure

- Open the DNS from output in the browser
- Refresh multiple times to see different web servers responding.

### SSH Access to Bastion Host
```bash
 ssh -i ~/techcorp-key.pem ec2-user@<bastion-public-ip>
 
 ```

### SSH Access to Private Instances (via Bastion)
- From the bastion station 
```bash
ssh ec2-user@<WEB_PRIVATE_IP>
```

- It will ask for password 
- Enter password as ser in the script.

### Connect to PostgreSQL database
- To ensure PostgreSQL is properly setup and running.
        - from database server connect to postgresql
           ```bash
            sudo -u postgres psql
          ```


## Checklist

- [x] VPC and subnets created in AWS Console
- [x] 4 EC2 instances running (1 bastion, 2 web, 1 db)
- [x] Load balancer distributing traffic to both web servers
- [x] Web application accessible via ALB DNS
- [x] Both web servers showing different instance IDs
- [x] SSH access to bastion from local machine
- [x] SSH access to web servers via bastion
- [x] SSH access to database server via bastion
- [x] PostgreSQL running and accessible on database server


## Troubleshooting

### ALB returns 502 Bad Gateway

- Possible reasons:

    - Web server user-data failed (yum install)

    - Apache did not start

    - Health check path does not exist

#### Cannot SSH into Bastion

- Ensure var.my_ip_address is correct.


### Private instances cannot update packages

- NAT Gateway may take time to initialize

- Re-run apply after a few minutes

## Destroy Infrastructure

```bash
terraform destroy
```

Type `yes` when prompted to confirm deletion.


        - **NOTE** : Comfirm to ensure all resourse are destroyed  to avoid incuring cost.




## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)