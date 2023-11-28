Deploy Multiple AWS Databricks Workspace with Customer-managed VPC, Private Links. Suitable for POCs.
=========================

In this example, we created modules and root level template to deploy multiple Databricks workspaces at scale easily. Users of this template minimally should do these:
1. Supply credentials (aws+databricks) and configuration variables for each workspaces . Your AWS user needs to be able to create IAM roles, VPCs and buckets.
2. Edit the locals block in `main.tf` to decide what & how many workspaces to deploy
3. You need a UC metastore to provide a metastore ID to the deployment. Follow the instructions here: https://docs.databricks.com/en/data-governance/unity-catalog/create-metastore.html or create it using a separate TF module.
4. Make sure to review the `variables.tf` to fit your region and deploy.
5. Run `terraform init` and `terraform apply` to deploy 1 or more workspaces into your VPC.
   
This modular design also allows customer to deploy, manage and delete `individual` workspace(s) easily, with minimal configuration needed. This template takes heavy reference (e.g. CMK module + Private Links) from https://github.com/andyweaves/databricks-terraform-e2e-examples from andrew.weaver@databricks.com and this repo is adapted to meet specific customer requirements.

## Project Folder Structure

    .
    ├── iam.tf
    ├── main.tf
    ├── outputs.tf
    ├── privatelink.tf
    ├── providers.tf
    ├── variables.tf
    ├── vpc.tf
    ├── modules   
        ├── mws_uc_catalog
            ├── main.tf               
            ├── providers.tf
            ├── variables.tf    
        ├── mws_workspace
            ├── main.tf         
            ├── variables.tf    
            ├── outputs.tf      
            ├── modules
                ├── mws_network
                    ├── main.tf
                    ├── variables.tf
                    ├── outputs.tf
                ├── mws_storage
                    ├── main.tf
                    ├── variables.tf
                    ├── outputs.tf


## Get Started

> Step 1: Clone this repo to local, set environment variables for `aws` and `databricks` providers authentication. Take a look at the `example.env` file. Copy it into a `.env` and populate the ENV variables according to your environment. There might be additional variables needed to fit your case.

> Step 2: Modify `variables.tf` or ovveride it using a `.tfvars` file, for each workspace you need to write a variable block like this, all attributes are required. The default region for this template is ap-southeast1

```terraform
workspaces = [
    {
      private_subnet_pair = { subnet1_cidr = "10.109.6.0/23", subnet2_cidr = "10.109.8.0/23" }
      workspace_name      = "test-workspace-1"
      prefix              = "tf-ws" // prefix decides subnets name
      root_bucket_name    = "test-workspace-1-rootbucket"
      tags = {
        "Name" = "test-workspace-1-tags",
        "Env"  = "test-ws-1"
        "Owner" = "owner@mail.com"
      }
      workspace_admins    = ["owner@mail.com"]
      metastore_id        = "METASTORE_ID" #Needs to be precreated
      catalog_name        = "poc-catalog"
      catalog_force_destroy = true
      catalog_isolation_mode = "ISOLATED"
      catalog_reuse_root_bucket = true
  }
]
```

> Step 3: Check your VPC and subnet CIDR, then run `terraform init` and `terraform apply` to deploy your workspaces; this will deploy multiple E2 workspaces into your VPC.

We are calling the module `mws_workspace` to create multiple workspaces by batch, you should treat this concept as a group of workspaces that share the same VPC in a region. If you want to deploy workspaces in different VPCs, you need to create multiple `mws_workspace` instances. 

In the default setting, this template creates one VPC (with one public subnet and one private subnet for hosting VPCEs). Each incoming workspace will add 2 private subnets into this VPC. If you need to create multiple VPCs, you should copy paste the VPC configs and change accordingly, or you can wrap VPC configs into a module, we leave this to you. 

## Private Links

In this example, we used 1 VPC for all workspaces, and we used backend VPCE for Databricks clusters to communicate with control plane. All workspaces deployed into the same VPC will share one pair of VPCEs (one for relay, one for rest api), typically since VPCEs can provide considerable bandwidth, you just need one such pair of VPCEs for all workspaces in each region. For HA setup, you can build VPCEs into multiple az as well. 

## Tagging

We added custom tagging options in `variables.tf` to tag your aws resources: in each workspace's config variable map, you can supply with any number of tags, and these tags will propagate down to resources related to that workspace, like root bucket s3 and the 2 subnets. Note that aws databricks itself does not support tagging, also the abstract layer of `storage_configuration`, and `network_configuration` does not support tagging. Instead, if you need to tag/enforce certain tags for `clusters` and `pools`, do it in `workspace management` terraform projects, (not this directory that deploys workspaces).

## Terraform States Files stored in remote S3
We recommend using remote storage, like S3, for state storage, instead of using default local backend. If you have already applied and retains state files locally, you can also configure s3 backend then apply, it will migrate local state file content into S3 bucket, then local state file will become empty. As you switch the backends, state files are migrated from `A` to `B`. 

```terraform
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-up-and-running-state-unique-hwang"
    key    = "global/s3/terraform.tfstate"
    region = "ap-southeast-1"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}
```

You should create the infra for remote backend in another Terraform Project, like the `aws_remote_backend_infra` project in this repo's root level - https://github.com/hwang-db/tf_aws_deployment/tree/main/aws_remote_backend_infra, since we want to separate the backend infra out from any databricks project infra. As shown below, you create a separate set of tf scripts and create the S3 and DynamoDB Table. Then all other tf projects can store their state files in this remote backend.

![alt text](https://raw.githubusercontent.com/databricks/terraform-databricks-examples/main/examples/aws-databricks-modular-privatelink/images/tf-remote-s3-backend.png?raw=true)

Tips: If you want to destroy your backend infra (S3+DynamoDB), since your state files of S3 and backend infra are stored in that exact S3, to avoid falling into chicken and egg problem, you need to follow these steps:
1. Comment out remote backend and migrate states to local backend
2. Comment out all backend resources configs, run apply to get rid of them. Or you can run destroy.

## Common Actions

### To add specific workspace(s)

You just need to supply with each workspace's configuration in root level `variables.tf`, similar to the examples given.
Then you need to add the workspaces you want into locals block and run apply.

