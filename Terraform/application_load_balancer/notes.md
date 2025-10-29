

# provider.tf 
* يمكن استخدام اكثر من نسخة من هذا الملف في كل موديول بحيث يمكن التعامل مع كل موديول على حدة 

### **Why Have More Than One `provider.tf`?**
1. **Explicit Provider Configuration per Module**  
   - Some modules may need different configurations (e.g., different AWS regions, credentials, or service endpoints).
   - Example: One module could deploy resources in `us-east-1`, while another uses `us-west-2`.

2. **Provider Versioning & Dependency Isolation**  
   - Some modules may require specific provider versions, which can be defined separately.
   - This avoids conflicts when using different versions in different parts of the project.

3. **Standalone Module Execution**  
   - If a module (`application_load_balancer/`) is used independently, it might define its own `provider.tf` to work outside the main project.
   - This makes the module reusable across multiple Terraform configurations.

### **How Terraform Handles Multiple `provider.tf` Files**
- Terraform **merges all provider configurations** when executing in the same workspace.
- If a module **does not define a provider**, it inherits the provider from the root (`~/Git/terraform-first-turorial/beginners/aws/provider.tf`).
- If a module **has its own provider.tf**, Terraform allows it to override or modify settings.

---

# security_group.tf

### **Breaking Down `security_group.tf` in Terraform (Application Load Balancer Perspective)**  

This file defines **AWS Security Groups (SGs)** for your **Application Load Balancer (ALB)** and the **backend instances**.

---

## **1️⃣ AWS Concepts Behind This Configuration**
- **Security Groups**: Act as virtual firewalls to control inbound and outbound traffic.  
- **Ingress Rules**: Define allowed incoming traffic (e.g., HTTP, SSH).  
- **Egress Rules**: Define allowed outgoing traffic (default: all traffic is allowed).  
- **Security Group Referencing**: Instances allow traffic only from the ALB’s security group.

---

## **2️⃣ Terraform Code Perspective**  

### **🔹 Security Group for ALB (`allow_http`)**
This security group **allows HTTP traffic (port 80) from anywhere (0.0.0.0/0) to the ALB**.

```hcl
resource "aws_security_group" "allow_http" {
  name        = "alb_http"
  description = "Allow http traffic to alb"
  vpc_id      = "enter_vpc_id" # Replace
   with actual VPC ID
   - the SG should be a part of VPC
   - if not assined it will use the default SG 

  ingress {
    description = "http for alb"
    from_port   = 80  # Allow incoming HTTP traffic
    to_port     = 80
```
- from_port and to_port allow a **range of ports** not a src and dist ports 
   
 ```hcl
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the internet to all IPs (not secure for production)
  }
```

```hcl
  egress {
    from_port   = 0  # Allow all outgoing traffic
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
```
* The protocol field specifies the network protocol (e.g., TCP, UDP, ICMP).
* protocol = "-1" (All Protocols)
* from_port = 0 & to_port = 0 (All Ports)
* Normally, these define a range of allowed ports.
* Setting both to 0 with protocol = "-1" means all ports are allowed.
```hcl
  tags = {
    Name = "allow_http_alb"
  }
}
```

### **🔹 Security Group for Backend Instances (`allow_http_instances`)**
This security group **allows traffic only from the ALB and SSH access from anywhere**.

```hcl
resource "aws_security_group" "allow_http_instances" {
  name        = "instances_http"
  description = "Allow http traffic to instances"
  vpc_id      = "enter_vpc_id" # Replace with actual VPC ID

  # Allow HTTP traffic *only* from ALB
  ingress {
    description = "http for instances"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.allow_http.id] # Allow only from ALB SG
  }
  ```
### **Breaking Down This Ingress Rule**  
```hcl
ingress {
  description = "http for instances"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_groups = [aws_security_group.allow_http.id] # Allow only from ALB SG
}
```

### **What This Rule Does?**
- **Allows incoming HTTP traffic (`TCP` on port `80`)**
- **BUT ONLY from a specific security group** (`aws_security_group.allow_http.id`)

---

### **Why Is Traffic Only Allowed From the ALB?**
#### **1️⃣ `security_groups = [aws_security_group.allow_http.id]`**
- Instead of allowing traffic from **any IP address (`cidr_blocks = ["0.0.0.0/0"]`)**,  
  this rule allows traffic **only from instances in the security group** `aws_security_group.allow_http.id`.  
- **This means**:
  - Only resources that **belong to that security group** can send HTTP traffic.
  - In this case, **it's most likely the Application Load Balancer (ALB)**.

---

#### **2️⃣ Why Not Use `cidr_blocks = ["0.0.0.0/0"]`?**
- If we had used:
  ```hcl
  cidr_blocks = ["0.0.0.0/0"]
  ```
  This would allow **HTTP traffic from anywhere on the internet**. ❌ **Security risk!**  

- Instead, using **`security_groups = [...]`** ensures:
  - Only traffic from the **ALB (or another specific security group)** is allowed.
  - Direct access to EC2 instances is **blocked** from the internet.
  - All traffic **must pass through the ALB**, making it more secure.
- AWS Security Groups operate at the instance level, not at the network level like traditional firewalls. When you specify another security group in the security_groups rule, AWS doesn’t check the source IP address directly but rather verifies the security group ID associated with the incoming traffic.
---

### **How This Works with the Application Load Balancer (ALB)**
1. **ALB Security Group (`allow_http`)**  
   - Allows inbound traffic **from the internet** (`0.0.0.0/0`) on port 80.
   - Sends traffic to the EC2 instances.

2. **Instance Security Group (`allow_http_instances`)**
   - **Does NOT allow traffic from the internet!**  
   - **Only allows HTTP traffic from ALB’s security group.**

✔ **As a result:**  
- **Users must go through the ALB** to reach the application.  
- **EC2 instances are protected** from direct internet access.  

---

### **Visual Representation**

[Internet] ---> [ALB Security Group] (allows 0.0.0.0/0 on port 80)
                   │
                   ▼
           [EC2 Security Group] (allows only from ALB's SG on port 80)

---

  ```hcl

  # Allow SSH access from anywhere (not secure for production)
  ingress {
    description = "ssh for instances"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0  # Allow all outgoing traffic
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_instances"
  }
}
```

---

## **3️⃣ Key Takeaways**
1. **`allow_http` SG (for ALB)**:  
   - Allows HTTP (port 80) traffic from anywhere.  
   - No SSH access.  
   - Can send traffic anywhere (egress open).  

2. **`allow_http_instances` SG (for backend instances)**:  
   - Only accepts HTTP from ALB’s security group.  
   - Allows SSH (port 22) from anywhere (not secure for production).  
   - Can send traffic anywhere (egress open).  

---
# instances.tf
غالبا ليس بها جديد 

### **Breakdown of `instances.tf` (Application Load Balancer Module) in Terraform**

This file defines **two EC2 instances** (`web1` and `web2`) that will be used as part of the Application Load Balancer (ALB) backend. It includes **instance provisioning**, **security group assignment**, and **remote execution** of commands on the instances.

---

## **AWS Perspective (Concepts Explained)**

1. **EC2 Instances (`web1` & `web2`)**  
   - These are virtual machines running in AWS.  
   - The instances are launched in a specific **subnet** and assigned to a **security group**.

2. **Security Group (`vpc_security_group_ids`)**  
   - The instances are assigned to `aws_security_group.allow_http_instances.id`, which ensures they only accept HTTP traffic from the ALB.

3. **Provisioning (`provisioner "remote-exec"`)**  
   - After the instance starts, Terraform runs **remote commands** using SSH.  
   - This installs and configures the Apache web server (`httpd`), ensuring it starts on boot.

---

## **Terraform Code Breakdown**

### **1️⃣ Defining the First EC2 Instance (`web1`)**
```hcl
resource "aws_instance" "web1" {
  ami           = "enter-ami-id"              # AMI ID for the instance (should be a Linux-based AMI)
  instance_type = "t2.micro"                  # Small instance type (eligible for AWS Free Tier)
  subnet_id     = "enter-subnet-id"           # The Subnet where the instance will be launched
  vpc_security_group_ids = [aws_security_group.allow_http_instances.id] # Assigning the security group
  key_name      = "enter-key-name"            # SSH Key to access the instance
```
- **AMI ID**: The base image for the instance (Amazon Linux, Ubuntu, etc.).
- **Instance Type**: `t2.micro` is a small, cost-effective instance type.
- **Subnet**: The instance must be placed in a **public or private subnet**.
- **Security Group**: `allow_http_instances.id` ensures it only allows traffic from the ALB.
- **SSH Key**: Required to access the instance.

---

### **2️⃣ Provisioning the EC2 Instance (Installing Apache)**
```hcl
provisioner "remote-exec" {
  inline = [
    "sudo yum install httpd -y",  # Install Apache Web Server
    "sudo service httpd start",   # Start the Apache service
    "sudo chkconfig httpd on"     # Enable it on system boot
  ]
```
- **`remote-exec`** allows Terraform to execute commands **inside the EC2 instance**.
- **Commands Executed**:
  1. Install Apache (`httpd`).
  2. Start the Apache service.
  3. Ensure Apache starts automatically after reboot.

---

### **3️⃣ SSH Connection Configuration**
```hcl
connection {
  type        = "ssh"
  user        = "ec2-user"  # Default user for Amazon Linux
  host        = aws_instance.web.public_ip
  private_key = file("${path.module}/key-name.pem")  # Use private key for authentication
}
```
- Uses **SSH** to connect to the instance.
- `ec2-user` is the **default user** for Amazon Linux.
- The instance's **public IP** is used to establish the SSH connection.
- The **private key** (`.pem` file) is required for authentication.

---

### **4️⃣ Defining the Second EC2 Instance (`web2`)**
```hcl
resource "aws_instance" "web2" {
  ami           = "enter-ami-id"
  instance_type = "t2.micro"
  subnet_id     = "enter-your-subnet-id"
  vpc_security_group_ids = [aws_security_group.allow_http_instances.id]
  key_name      = "enter-key-name"
```
- This is similar to `web1` but is a separate instance.
- It will be placed in the **same subnet** and **same security group**.

---

### **5️⃣ Provisioning for `web2` (Incorrect Command)**
```hcl
inline = [
  "sudo yum install https -y",  # ❌ Typo: Should be "httpd", not "https"
  "sudo service httpd start",
  "sudo chkconfig httpd on"
]
```
- **🚨 Error Alert:** `"sudo yum install https -y"` is incorrect.  
  - It should be `"sudo yum install httpd -y"` (like in `web1`).

---

## **Key Takeaways**
1. **Two EC2 Instances (`web1` & `web2`)**  
   - Launched inside a specific subnet.
   - Attached to a security group that allows **only ALB traffic**.

2. **Security Measures**
   - No direct internet access (except via ALB).
   - SSH key authentication is required.

3. **Provisioning**
   - Installs and starts the **Apache web server** (`httpd`).
   - **Typo in `web2`** should be corrected (`https → httpd`).

---

# loadbalancer.tf
### **Breakdown of `loadbalancer.tf` (Application Load Balancer Module) in Terraform**

This file defines an **Application Load Balancer (ALB)**, its **listener**, and how it forwards traffic to a **target group**.

---

## **AWS Perspective (Concepts Explained)**

### **1️⃣ Application Load Balancer (ALB)**
- A **highly scalable** and **managed AWS service** that distributes HTTP/S traffic across multiple targets (EC2 instances, containers, or Lambda functions).
- **Key Features**:
  - Operates at **Layer 7 (HTTP/S)**.
  - Supports **host-based & path-based routing**.
    - Routes traffic based on the domain name (Host header) in the request.
    - Useful when hosting multiple applications on the same ALB.
    - app1.example.com → Routes to Target Group 1
    - app2.example.com → Routes to Target Group 2
  - **Increases availability** by distributing requests across multiple instances.
  - Can be **public or internal**.

### **2️⃣ ALB Listener**
- Listens for **incoming connections** on a specific **port & protocol**.
- Defines **rules** for forwarding requests (e.g., sending traffic to target groups).

### **3️⃣ Security Group**
- Controls **which IPs and protocols** can access the ALB.
- Attached using `security_groups = [aws_security_group.allow_http.id]`.

### **4️⃣ Subnets**
- The ALB must be placed in **at least two subnets** across different **Availability Zones**.
- This ensures **high availability**.

---

## **Terraform Code Breakdown**

### **1️⃣ Defining the Application Load Balancer**
```hcl
resource "aws_lb" "my-lb" {
  name               = "lb-tf"                           # Name of the Load Balancer
  internal           = false                             # False = Public-facing LB (True = Internal LB)
  load_balancer_type = "application"                    # Specifies ALB (vs. NLB or Gateway LB)
  security_groups    = [aws_security_group.allow_http.id]  # Security Group for ALB

  subnets            = ["subnet-id1", "subnet-id2", "subnet-id3", "subnet-id4"] # Requires at least two subnets in different AZs

  enable_deletion_protection = false   # Ensures the LB can be deleted

  tags = {
    name = "my-first-load-balancer"
  }
}
```
### **📝 Explanation:**
1. **`internal = false`** → The ALB is publicly accessible.
2. **`load_balancer_type = "application"`** → Creates an Application Load Balancer (ALB).
3. **`security_groups`** → Controls inbound/outbound traffic to/from ALB.
4. **`subnets`** → The ALB spans across multiple **Availability Zones** for redundancy.
5. **`enable_deletion_protection = false`** → Allows deleting the ALB when needed.

---

### **2️⃣ Creating an ALB Listener**
```hcl
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.my-lb.arn  # Attach listener to the ALB
  port              = "80"               # Listens on port 80 (HTTP)
  protocol          = "HTTP"             # Handles HTTP traffic
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-lb.arn  # Send traffic to the target group
  }
}
```
### **📝 Explanation:**
1. **Listener is attached to ALB (`aws_lb.my-lb.arn`)**.
2. **Listens on port `80` for HTTP traffic**.
3. **Defines a default action (`type = forward`)**:
   - Any request received by the ALB will be forwarded to the **target group**.

---

# target_group_attach.tf

### **Breaking Down `target_group_attach.tf` Configuration**

This Terraform configuration is responsible for defining an **AWS Application Load Balancer (ALB) Target Group** and attaching EC2 instances to it.

---

## **AWS Concept Perspective**
- **Application Load Balancer (ALB)** distributes incoming traffic across multiple targets (EC2 instances, containers, Lambda, etc.).
- **Target Groups** are logical groups of backend servers that the ALB forwards traffic to.
- **Target Group Attachments** link individual EC2 instances to the Target Group, enabling load balancing.

---

## **Terraform Code Perspective**
### **1️⃣ Target Group Definition**
```hcl
resource "aws_lb_target_group" "target-lb" {
  name     = "lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "enter_vpc_id"
}
```
- **`name = "lb-tg"`** → Assigns a name to the Target Group.
- **`port = 80`** → Defines the port on which the Target Group listens (HTTP traffic).
- **`protocol = "HTTP"`** → Specifies that the target group will handle HTTP traffic.
- **`vpc_id = "enter_vpc_id"`** → Associates the Target Group with a specific **VPC**.

This Target Group acts as a **logical container for backend EC2 instances**.

---

### **2️⃣ Attaching EC2 Instances to the Target Group**
Each `aws_lb_target_group_attachment` associates an **EC2 instance** with the target group.

#### **EC2 Instance 1 (`web1`)**
```hcl
resource "aws_lb_target_group_attachment" "test1" {
  target_group_arn = aws_lb_target_group.target-lb.arn
  target_id        = aws_instance.web1.id
  port             = 80
}
```
- **`target_group_arn = aws_lb_target_group.target-lb.arn`** → Links the attachment to the Target Group.
- **`target_id = aws_instance.web1.id`** → Attaches EC2 instance `web1` to the Target Group.
- **`port = 80`** → Specifies that this instance listens on port 80.

#### **EC2 Instance 2 (`web2`)**
```hcl
resource "aws_lb_target_group_attachment" "test2" {
  target_group_arn = aws_lb_target_group.target-lb.arn
  target_id        = aws_instance.web2.id
  port             = 80
}
```
- Same as above but attaches **EC2 instance `web2`**.

---

## **How It Works in AWS**
1. **Incoming traffic reaches the ALB listener (Port 80).**
2. **The listener forwards traffic to the Target Group (`target-lb`).**
3. **The Target Group distributes requests between `web1` and `web2`.**
4. **Each EC2 instance processes requests and sends responses back.**

---

## **Example Terraform Workflow**
1. **Define EC2 instances (`web1`, `web2`).**
2. **Create a Target Group (`target-lb`).**
3. **Attach EC2 instances (`web1`, `web2`) to the Target Group.**
4. **Define an ALB listener that forwards requests to this Target Group.**

---