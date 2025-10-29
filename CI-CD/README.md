# CI/CD Pipeline

This directory contains Jenkins pipeline configurations for automated build, test, security scanning, and deployment processes.

## 🚀 Jenkins Pipeline Overview

A comprehensive CI/CD pipeline that automates the entire software delivery process from code commit to production deployment.

### Pipeline Stages

1. **Source Control** - Git checkout from repository
2. **Compile** - Maven compilation
3. **Test** - Automated test execution
4. **Security Scan** - File system vulnerability scanning with Trivy
5. **Code Quality** - SonarQube static analysis
6. **Quality Gate** - Quality threshold validation
7. **Build** - Maven package creation
8. **Artifact Publishing** - Deployment to Nexus repository
9. **Docker Build** - Container image creation and tagging
10. **Image Security** - Docker image vulnerability scanning
11. **Image Publishing** - Push to Docker registry
12. **Kubernetes Deployment** - Automated deployment to K8s cluster
13. **Verification** - Deployment status validation

## 🛡️ Security Features

- **Trivy Security Scanning** (file system and container images)
- **SonarQube Quality Gates**
- **Vulnerability reporting** with HTML outputs
- **Automated email notifications** with security reports

## 📧 Notifications

Automated email notifications with:
- Build status (Success/Failure)
- Pipeline console output links
- Security scan reports attached
- Color-coded status banners

## 🔧 Technologies

- **Jenkins** - Pipeline orchestration
- **Maven** - Build automation
- **SonarQube** - Code quality
- **Trivy** - Security scanning
- **Docker** - Containerization
- **Nexus** - Artifact repository
- **Kubernetes** - Container orchestration