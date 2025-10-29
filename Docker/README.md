# Docker Configurations

This directory contains Docker configurations and containerized application setups for various use cases.

## 🐳 Contents

### 1. **Web Application Stack** (`docker-compose-web.yml`)
Multi-service setup with Nginx web server and MySQL database:
- **Nginx**: Web server with custom HTML volume mount
- **MySQL**: Database with persistent data storage
- **Network Isolation**: Separate frontend/backend networks

### 2. **DevOps Toolchain** (`docker-compose-devops.yml`)
Complete DevOps environment with:
- **Jenkins**: CI/CD automation server
- **SonarQube**: Code quality analysis
- **Nexus**: Artifact repository management
- **Shared Network**: Isolated DevOps network

### 3. **PHP Application** (`docker-compose-php.yml`)
PHP application with MySQL database:
- **Custom PHP/Apache**: Built from Dockerfile
- **MySQL**: Database service
- **Dependency Management**: Service ordering

### 4. **PHP Dockerfile** (`Dockerfile`)
Custom PHP 8.0 Apache image with:
- MySQL extensions enabled
- Project files copied to web root
- Apache port exposure

## 🚀 Quick Start

### Web Application Stack
```bash
docker-compose -f docker-compose-web.yml up -d
```