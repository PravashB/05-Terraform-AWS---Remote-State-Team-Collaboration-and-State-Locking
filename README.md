# 05-Terraform-AWS---Remote-State-Team-Collaboration-and-State-Locking
In this lab, we will simulate real-world team collaboration using the same remote backend (S3 + DynamoDB) we configured earlier.
![alt text](/Images/Pravash_Logo_Small.png)

## Objective
> - We'll see how the **state file locking and lock contention** are happening.
> - We'll understand how **Terraform prevents conflicts** when multiple users work on the same infrastructure.

## Pre-requisites
> - Completed 04-Terraform-AWS---Remote-State-with-S3-and-DynamoDB-Locking lab successfully.
> - Remote backend (S3 + DynamoDB) working.
> - Terraform Installed.
> - Two separate folders (simulate two team members).

## Folder Structure
```
05-Terraform-AWS---Remote-State-Team-Collaboration-and-State-Locking/
├── team_member_1/
│   ├── backend.tf
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── team_member_2/
│   ├── backend.tf
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
└── README.md
```
**IMP**: We'll keep the same backend configured in both folders.

## Step 1: Setup Two Separate Workspaces & Configure the terraform files.

I'm going to simulate **two users** (Team Member 1 and Team Member 2).
1. Let's first Create two folders:
    - `team_member_1/`
    - `team_member_2/`

![alt text](/Images/image.png)

2. Then Inside both folders, create the below files:
    - `backend.tf`
    - `provider.tf`
    - `variables.tf`
    - `main.tf`
    - `outputs.tf`
    - `terraform.tfvars`
```
touch backend.tf provider.tf variables.tf main.tf outputs.tf terraform.tfvars
```
![alt text](/Images/image-1.png)

3. **backend.tf (for both)**
```
terraform {
  backend "s3" {
    bucket         = "terraform-bootstrap-pro-lab"
    key            = "projects/sample-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-pro-lab"
    encrypt        = true
  }
}
```
> **IMP:** Both "team members" will work on the **same state file** - so locking matters a lot here!!

4. **provider.tf (for both)**
```
provider "aws" {
    region = var.aws_region
}
```

5. **variables.tf (for both)**
```
variable "aws_region" {
    description = "AWS Region"
    type        = string
    default     = "us-east-1"
}
```
6. **terraform.tfvars (for both)**
```
aws_region = "us-east-1"
```
7. **main.tf**
- Each Team Member will try to create a different S3 bucket. So, our main.tf files will be configured differently for each.

**For team_member_1/main.tf**
```
resource "aws_s3_bucket" "member1_bucket" {
  bucket = "team-member-1-bucket-pro-${random_integer.suffix.result}"

  tags = {
    Name = "TeamMember1Bucket"
  }
}

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}
```

**For team_member_1/main.tf**
```
resource "aws_s3_bucket" "member2_bucket" {
  bucket = "team-member-2-bucket-pro-${random_integer.suffix.result}"

  tags = {
    Name = "TeamMember2Bucket"
  }
}

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}
```
![alt text](/Images/image-2.png)
**WHAT & WHY**
> - Both the users are sharing the same `terraform.tfstate` file.
> - If one user is working on the terraform apply, **`state locking`** happens.
> - If another user tries to apply at the same time, they see an **error** and have to **wait**.

## Step 2: Simulate the Collaboration
Now, Let's see how state locking happens in real.

1. Open two terminals side by side and run:
```terraform init```

![alt text](/Images/image-3.png)

- In the first terminal, run
```terraform plan -out=tfplan```

![alt text](/Images/image-6.png)

2. Now, type `terraform plan` in the second terminal and keep it ready (DO NOT PRESS ENTER YET).
- In terminal 1, enter `terraform apply tfplan` and after 2-3 seconds run `terraform plan` in terminal 2.

## Expected Output in Terminal 2
We could see, that While the resources were created by Team Member 1, Team Member 2 got an error.

![alt text](/Images/image-4.png)

> - This is **State Locking in Action**.
> - Terraform uses **DynamoDB locking** to prevent **corruption or overwriting** of our state.

3. Now, that `Team Member 1` is done with successfully apply and resource creation, what will happen if `Team Member 2` goes ahead and **runs** `terraform plan`?

> Let's undestand this very clearly.

1. Let's first create a fresh `terraform plan -out=tfplan` by **Team Member 1**

![alt text](/Images/image-5.png)

2. Then, let's run the `terraform apply` and see the results in AWS Account.

![alt text](/Images/image-7.png)

- We can now see the bucket is created successfully [id=team-member-1-bucket-pro-6185]

![alt text](/Images/image-8.png)

3. Let's now go to Terminal 2 and run the `terraform plan -out=tfplan` by **Team Member 2**.

- Okay, Here I can see something different. It states about destroy and then create.

![alt text](/Images/image-9.png)

Team Member 2 will destroy the bucket created by Team Member 1 and create a new `member2_bucket`.

4. Let's see this by running `terraform apply`:

![alt text](/Images/image-10.png)

- In the AWS Account also, we can validate how the S3 bucket name changed from team-member-1-bucket to team-member-2-bucket.

![alt text](/Images/image-11.png)

> **This brings us to a very important question. How Collaboration works safely?**

5. Before that, let's destroy the resource created.

    ``` terraform destroy -auto-approve```

![alt text](/Images/image-12.png)


## Important Note: How Collaboration Works Safely

**Single Shared State File**
- Both team members are working against the same remote state (`terraform.tfstate` stored in S3).
- This means all resources across both configurations must be tracked consistently.

**State Locking Only Prevents Simultaneous Writes**
- When one member runs `terraform apply`, the DynamoDB lock ensures no one else can write to the state at the same time.
- However, it doesn't prevent us from **applying incomplete or out-of-sync configurations**

## WARNING

If:
 - **Member 1** applies their resource,
 - **Member 2** runs `terraform plan` or `apply` **without pulling the latest state or without pulling the latest state** or without pulling Member 1's resource in their config,

 Terraform will detect a mismatch:
 > ``` "This resource exists in state but not in the config → plan to destroy.”```

 This can **accidentally destroy** the other team member’s resources (Which we saw just now).

## End of Lab
We'll understand in another lab how we can avoid conflicts, destroy and messy management using separate terraform state files and **Terraform Workspaces**

---
> Prepared By: Pravash

> Last Updated: May 2025