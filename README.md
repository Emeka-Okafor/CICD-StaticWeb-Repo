# 🚀 Static Website CI/CD Pipeline on AWS with Terraform

This project sets up a complete Continuous Integration and Continuous Deployment (CI/CD) pipeline using AWS services and Terraform for a **static website**.

---

## 🛠️ Technologies Used

- **Terraform**
- **AWS S3** (Website Hosting & Artifact Storage)
- **AWS CodePipeline** (CI/CD Orchestration)
- **AWS CodeBuild** (Build Stage)
- **AWS KMS** (Artifact Encryption)
- **AWS IAM** (Permissions & Access Control)
- **AWS CodeStar Connection** (GitHub Integration)
- **AWS CloudWatch Logs** (Build Logs)

---

## 📁 Project Structure

```bash
.
├── main.tf              # Main Terraform code
├── buildspec.yml        # Build instructions for CodeBuild
└── README.md            # Documentation

Architechture Diagram

GitHub Repo → CodePipeline
    └── Source Stage (CodeStarConnection)
        └── Build Stage (CodeBuild)
            └── Deploy Stage (Upload to S3 Website Bucket)

✅ Features

Automatically deploys a static website from GitHub when code is pushed to main branch.

Public S3 bucket for website hosting with proper access policy.

Private S3 bucket for storing build artifacts.

KMS encryption enabled for artifacts.

CloudWatch logging enabled for build monitoring.

IAM roles configured for fine-grained permission control.

🔐 Resources Created
🔷 S3 Buckets
Website Bucket – Hosts the static website.

CI/CD Bucket – Stores build artifacts and logs.

🔷 CodePipeline
Automates source, build, and deploy stages.

🔷 CodeBuild
Pulls code from GitHub and builds it using buildspec.yml.

🔷 KMS
Encrypts the artifacts stored in the CI/CD bucket.

🔷 IAM Roles & Policies
For CodeBuild and CodePipeline to assume required permissions.

🔷 CloudWatch Logs
Captures build output and errors for debugging.

⚙️ How to Use
1. ✅ Prerequisites
AWS CLI configured

GitHub repository created with index.html and error.html

Terraform installed

buildspec.yml file in the root of your GitHub repo

2. 🔧 Configure CodeStar GitHub Connection
Before applying this Terraform, manually create a CodeStar Connection from AWS Console and authorize GitHub access. Then update your Terraform to use the ARN.

3. 📥 Clone the Repository
git clone https://github.com/your-username/your-repo.git
cd your-repo

4. 🔨 Initialize Terraform
terraform init

5. 🚀 Apply Terraform Configuration
terraform apply

6. 🌐 Access Your Website
After the deployment, Terraform will output a public URL to access your static website.

🧪 Sample buildspec.yml

version: 0.2

phases:
  install:
    runtime-versions:
      nodejs: 14
  build:
    commands:
      - echo "Build phase - nothing to build for static site"
artifacts:
  files:
    - '**/*'

🧹 Cleanup
To avoid incurring charges, destroy all resources when you're done:
terraform destroy

📌 Notes
This setup uses AdministratorAccess for the CodeBuild role. In production, you should use least privilege.

Ensure your buildspec.yml exists in the GitHub repo.

You might need to re-authorize CodeStar connection if GitHub access expires.



🙋‍♂️ Author
Idris Emeka Okafor
DevOps Engineer | AWS | Terraform | CI/CD










 
 
 
