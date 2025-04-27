# AWS-DevSecOps-Architecture
RayaneFlix is a fully automated, secure, and highly available cloud infrastructure project designed to host a Netflix-like streaming web application on AWS.   This project follows DevSecOps principles, integrating security, automation, high availability, and cost optimization throughout the entire deployment lifecycle.


The architecture uses Infrastructure as Code (IaC) with Terraform and Ansible, a complete CI/CD pipeline with Jenkins and SonarQube, and includes dynamic security analysis with SAST, DAST, and dependency scanning tools.

<div align="center">
  <img src="./public/assets/DevSecOps.png" alt="Logo" width="100%" height="100%">

  <br>
  <a href="http://netflix-clone-with-tmdb-using-react-mui.vercel.app/">
    <img src="./public/assets/netflix-logo.png" alt="Logo" width="100" height="32">
  </a>
</div>

<br />

<div align="center">
  <img src="./public/assets/home-page.png" alt="Logo" width="100%" height="100%">
  <p align="center">Home Page</p>
</div>
---

## 🌟 Project Objectives

- Deploy a **highly available**, **resilient**, and **secure** streaming website infrastructure on AWS.
- **Automate** infrastructure creation and server configuration using **Terraform** and **Ansible**.
- **Integrate security** early in the development lifecycle using DevSecOps practices (SAST/DAST analysis).
- **Optimize costs** through dynamic resource provisioning and efficient cloud design.
- Achieve **zero manual intervention** deployment with fully automated pipelines.

---

## 🛠️ Main Features

- **Infrastructure as Code** using Terraform for AWS resource creation.
- **Automated server configuration** (Ansible) to install and configure Jenkins, SonarQube, Docker, Trivy, npm.
- **CI/CD pipeline** with Jenkins integrating:
  - Source code analysis (SonarQube)
  - Dependency vulnerability scanning (OWASP Dependency Check)
  - Container image security scanning (Trivy)
  - Docker image building and deployment
- **Reverse Proxy and CDN** with AWS CloudFront.
- **Web Application Firewall (WAF)** with ModSecurity EC2 instance.
- **Secure access** to EC2 instances using AWS Systems Manager (no SSH exposure).
- **ALB Load Balancing** for traffic distribution across multi-AZ instances.
- **Lambda Functions** for automating post-deployment scripts and configuration.
- **Automated security reports** emailed after each pipeline execution.

---

## 🏗️ Architecture Overview

