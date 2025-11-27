# Web App Terraform CI/CD Project

<p align="center">
  <img src="https://img.shields.io/badge/AWS-Terraform-orange?logo=amazonaws" />
  <img src="https://img.shields.io/badge/GitHub_Actions-CI%2FCD-black?logo=githubactions" />
  <img src="https://img.shields.io/badge/AWS-AppRunner-blue?logo=amazonaws" />
  <img src="https://img.shields.io/badge/AWS-ECR-yellow?logo=amazonaws" />
</p>

<p align="center">
  End‑to‑end CI/CD pipeline using Terraform IaC, GitHub OIDC, AWS ECR, and App Runner.
</p>

---

## 📘 Overview
This project deploys a containerized web application using Terraform and an automated GitHub Actions CI/CD pipeline. Builds are triggered on each push to `main`, and the application is automatically deployed to AWS App Runner using images stored in Amazon ECR.

---

## 🧱 Architecture Overview

### AWS Components
- Amazon ECR repository for Docker images
- AWS App Runner service for running the application
- IAM roles for Terraform and CI/CD execution
- S3 backend for Terraform state
- DynamoDB table for state locking

### CI/CD Flow
1. Push to `main`  
2. GitHub Actions builds Docker image  
3. Authenticate via OIDC  
4. Push image to ECR  
5. Terraform apply triggers App Runner deploy  
6. App Runner pulls new image and updates the live app

---

## 📂 Repository Structure

```
terraform-bootstrap/          → S3 backend + DynamoDB lock
terraform/                    → App Runner + IAM + ECR + networking
app/                          → Application source + Dockerfile
.github/workflows/app-ci.yml  → CI/CD pipeline
```

---

## 🏁 Getting Started

### 1. Bootstrap Backend
```
cd terraform-bootstrap
terraform init
terraform apply
```

### 2. Deploy Infra
```
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Trigger CI/CD
Push any commit to `main`:
- Docker image built
- Pushed to ECR
- App Runner service redeployed

---

## 🌐 Accessing the Application
Retrieve the App Runner URL in AWS console or via CLI:
```
aws apprunner list-services
```

---

## 🔄 CI/CD Summary
- Automated Docker builds
- Secure GitHub OIDC authentication
- Zero-downtime App Runner deploys
- ECR image versioning with SHA tags

---

## 🧹 Destroy
Destroy in this order:
```
cd terraform
terraform destroy
cd ../terraform-bootstrap
terraform destroy
```

---

## 📞 Contact
GitHub: https://github.com/bmihaly-dev
