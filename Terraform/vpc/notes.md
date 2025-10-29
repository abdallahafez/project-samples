
---
# main.tf & var.tf
## **AWS Perspective:**
The files define the creation of a **VPC (Virtual Private Cloud)** and specify **CIDR blocks** for the VPC and its associated subnets. Here's what each resource and variable represents in AWS:

1. **VPC (`aws_vpc`)**:  
   - لاحظ أن البابلك والبرايفت نتورك هما جزء من النتورك الرئيسية CIDR block  
   - A VPC is a logically isolated network in AWS where you can launch AWS resources .
   - The `cidr_block` specifies the range of IP addresses available within this VPC.

2. **Subnets**:  
   - These are smaller networks within the VPC that allow segmentation of resources.  
   - The CIDR blocks provided in `var.tf` define:  
     - **Public Subnet:** A subnet typically associated with an Internet Gateway to allow public internet access.  
     - **Private Subnet:** A subnet where instances have no direct access to the internet and are used for internal communication.

---

## **Terraform Code Perspective:**
### **1. `main.tf`**
This file defines the VPC resource using the Terraform AWS provider.

```hcl
resource "aws_vpc" "collabnix_vpc" {
  cidr_block = var.cidr_block  # Using a variable for flexibility

  tags = {
    project = "Collabnix"
    department = "Automation"
  }
}
```
- **`resource "aws_vpc"`** → Creates a VPC in AWS.  
- **`cidr_block = var.cidr_block`** → Assigns the CIDR block from the `var.tf` file (default: `10.0.0.0/16`).  
- **Tags (`tags = {}`)** → Helps in organizing and managing resources (e.g., project name, department).

---

### **2. `var.tf`**
This file defines Terraform **variables**, making the configuration flexible.

```hcl
variable "cidr_block" {
  description = "CIDR range for your VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```
- Defines the CIDR block for the VPC.
- **Default value:** `10.0.0.0/16`, meaning the VPC can have **65,536** IPs.

```hcl
variable "public_subnet_cidr" {
  description = "CIDR range for your public Subnet"
  type        = string
  default     = "10.0.1.0/24"
}
```
- Defines a **public subnet** (default CIDR `10.0.1.0/24` → 256 IPs).

```hcl
variable "private_subnet_cidr" {
  description = "CIDR range for your private Subnet"
  type        = string
  default     = "10.0.2.0/24"
}
```
- Defines a **private subnet** (default CIDR `10.0.2.0/24` → 256 IPs).

---
# subnet.tf
---

## **AWS Perspective:**
The `subnet.tf` file defines **subnets** within the **VPC**. A **subnet** is a smaller network within a VPC, used to segment resources based on security, accessibility, and operational needs.

### **Key Concepts:**
1. **Public Subnet (`aws_subnet.publicsubnet`)**:
   - This subnet is assigned an IP range (`cidr_block` from `var.public_subnet_cidr`).
   - It is marked as **public** because `map_public_ip_on_launch = true`, meaning any EC2 instance launched in this subnet will automatically receive a **public IP**.
   - Typically, a public subnet is connected to an **Internet Gateway (IGW)** to allow internet access.

2. **Private Subnet (`aws_subnet.privatesubnet`)**:
   - Another subnet within the same VPC, assigned its own **CIDR block** (`var.private_subnet_cidr`).
   - **No `map_public_ip_on_launch`**, meaning instances in this subnet do **not** get a public IP.
   - Used for internal services like databases, application servers, etc.

---

## **Terraform Code Perspective:**
### **1. `subnet.tf`**
This file creates both the **public** and **private** subnets inside the VPC.

#### **Public Subnet**
```hcl
resource "aws_subnet" "publicsubnet" {
  vpc_id     = aws_vpc.collabnix_vpc.id  # Associates the subnet with the VPC
  cidr_block = var.public_subnet_cidr    # Gets CIDR from variables
  map_public_ip_on_launch = "true"       # Ensures public IPs are assigned

  tags = {
    project = "Collabnix"
    department = "Automation"
  }
}
```
- **`vpc_id = aws_vpc.collabnix_vpc.id`** → Attaches the subnet to the VPC.
- **`cidr_block = var.public_subnet_cidr`** → Assigns the IP range.
- **`map_public_ip_on_launch = "true"`** → Ensures that instances launched here get a **public IP**.
- **Tags (`tags = {}`)** → Helps identify resources.

#### **Private Subnet**
```hcl
resource "aws_subnet" "privatesubnet" {
  vpc_id     = aws_vpc.collabnix_vpc.id  # Associates the subnet with the VPC
  cidr_block = var.private_subnet_cidr   # Gets CIDR from variables

  tags = {
    project = "Collabnix"
    department = "Automation"
  }
}
```
- **No `map_public_ip_on_launch`**, meaning instances here **won't** get a public IP.
- Typically used for **internal workloads** (databases, backend services, etc.).

---
---
# internetgateway.tf
Let's break this down from both an **AWS perspective** and a **Terraform code perspective**.

---

## **AWS Perspective:**
The `internetgateway.tf` file defines an **Internet Gateway (IGW)** for the **VPC**. 

### **Key Concepts:**
1. **Internet Gateway (`aws_internet_gateway`)**:  
   - It allows resources (e.g., EC2 instances) in the **public subnet** to communicate with the internet.
   - It is **attached to the VPC**, providing a **route** for external traffic.
   - It works **<span style="color:red;">only with subnets that have public IP addresses</span>** and are configured with proper **route tables**.

---

## **Terraform Code Perspective:**
### **1. `internetgateway.tf`**
This file creates an **Internet Gateway** and attaches it to the **VPC**.

```hcl
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.collabnix_vpc.id  # Attaches the IGW to the VPC

  tags = {
    project = "Collabnix"
    department = "Automation"
  }
}
```

### **Code Breakdown:**
- **`resource "aws_internet_gateway"`** → Creates an Internet Gateway in AWS.
- **`vpc_id = aws_vpc.collabnix_vpc.id`** → Attaches it to the **VPC** created earlier.
- **Tags (`tags = {}`)** → Helps identify and manage the IGW.

---

## **How This Fits into the Network:**
1. The **public subnet** has `map_public_ip_on_launch = true`, meaning instances get a **public IP**.
2. The **Internet Gateway (IGW)** is attached to the VPC, providing internet access.
3. To enable traffic flow, a **Route Table** must be created, pointing `0.0.0.0/0` to the **IGW**.

---
# routetable.tf
Let's break this down from both an **AWS perspective** and a **Terraform code perspective**.

---

## **AWS Perspective:**
The `routetable.tf` file defines **route tables**, which are essential for directing network traffic within a VPC. 

### **Key Concepts:**
1. **Route Table (`aws_route_table`)**:  
   - A route table is a set of rules (**routes**) that determine where network traffic is directed.
   - Each **subnet** in a VPC must be associated with a route table.

2. **Public Route Table (`aws_route_table.public`)**:  
   - Directs all outbound internet traffic (`0.0.0.0/0`) to the **Internet Gateway (IGW)**.
   - Used for **public subnets** where resources need direct internet access (e.g., web servers).

3. **Private Route Table (`aws_route_table.private`)**:  
   - Directs outbound internet traffic (`0.0.0.0/0`) to a **NAT Gateway (NGW)**.
   - Used for **private subnets**, allowing them to access the internet **without being publicly accessible** (e.g., for software updates).

---

## **Terraform Code Perspective:**
### **1. `routetable.tf`**
This file defines both **private and public route tables**.

#### **Private Route Table**
```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.collabnix_vpc.id  # Associates the route table with the VPC

  route {
    cidr_block = "0.0.0.0/0"  # Default route (all traffic)
    nat_gateway_id = aws_nat_gateway.ngw.id  # Routes traffic through the NAT Gateway
  }

  tags = {
    project = "Collabnix"
    department = "Automation"
  }
}
```
- **`route {}` block**:  
  - `cidr_block = "0.0.0.0/0"` → Means **all outbound internet traffic**.
  - `nat_gateway_id = aws_nat_gateway.ngw.id` → Routes traffic through a **NAT Gateway (NGW)** instead of exposing private subnet resources directly to the internet.
- Used for **private subnets** that need internet access but **should not** be publicly reachable.

---

#### **Public Route Table**
```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.collabnix_vpc.id  # Associates the route table with the VPC

  route {
    cidr_block = "0.0.0.0/0"  # Default route (all traffic)
    gateway_id = aws_internet_gateway.igw.id  # Routes traffic through the Internet Gateway
  }

  tags = {
    project = "Collabnix"
    department = "Automation"
  }
}
```
- **`route {}` block**:  
  - `cidr_block = "0.0.0.0/0"` → Means **all outbound internet traffic**.
  - `gateway_id = aws_internet_gateway.igw.id` → Routes traffic through the **Internet Gateway (IGW)**.
- Used for **public subnets**, allowing direct internet access.

---

## **How This Fits into the Network:**
1. **Public Subnet Traffic Flow**:  
   - Instance → Route Table → **Internet Gateway** → Internet.  
   - This allows **public-facing resources** like web servers to be accessible.

2. **Private Subnet Traffic Flow**:  
   - Instance → Route Table → **NAT Gateway** → Internet.  
   - This allows private instances to access the internet for updates while remaining **inaccessible from the internet**.

---
# natgateway.tf
* لابد له من EIB 
* لا يمكنه استخدام dynamic public IP 
Let's break down the `natgateway.tf` file from both an **AWS perspective** and a **Terraform code perspective**.

---

## **AWS Perspective:**
The `natgateway.tf` file defines a **NAT Gateway (NGW)**, which is used to enable **internet access** for resources inside **private subnets** without exposing them directly to the internet.

### **Key Concepts:**
1. **NAT Gateway (`aws_nat_gateway`)**:  
   - Allows instances in a **private subnet** to access the internet (for updates, API calls, etc.).
   - Prevents inbound traffic from the internet, ensuring security.
   - Requires an **Elastic IP (EIP)** for external communication.
   - Must be placed in a **public subnet** (not private) because it needs direct internet access.

2. **Elastic IP (`aws_eip`)**:  
   - A **static, public IP address** that remains attached to the NAT Gateway.
   - Used for **outbound** traffic from private instances.

3. **Dependency on Internet Gateway (`depends_on = [aws_internet_gateway.igw]`)**:  
   - Ensures that the **Internet Gateway (IGW)** is created before the NAT Gateway.
   - The **IGW** is necessary because the NAT Gateway must be in a public subnet to work.

---

## **Terraform Code Perspective:**
### **1. `natgateway.tf`**
This file creates a **NAT Gateway**.

```hcl
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id  # Elastic IP for the NAT Gateway
  subnet_id     = aws_subnet.privatesubnet.id  # Subnet where NAT Gateway is deployed

  tags = {
    project = "Collabnix"
    department = "Automation"
  }

  depends_on = [aws_internet_gateway.igw]  # Ensures IGW is created first
}
```

### **Code Breakdown:**
- **`allocation_id = aws_eip.nat_eip.id`** → Attaches an **Elastic IP (EIP)** to the NAT Gateway.
- **`subnet_id = aws_subnet.privatesubnet.id`** → Specifies the subnet for the NAT Gateway.  
  **⚠️ Issue:** The NAT Gateway should be in a **public subnet**, not a private one. 
  تم تصحيح الخطا
  - **`subnet_id = aws_subnet.publicsubnet.id`** → Specifies the subnet for the NAT Gateway.  
- **Tags (`tags = {}`)** → Helps with resource identification.
- **`depends_on = [aws_internet_gateway.igw]`** → Ensures that the **Internet Gateway** is created first.

---

## **How This Fits into the Network:**
1. **Public Subnet Traffic Flow** (Uses an **Internet Gateway**):  
   - **Public Instance** → **Route Table** → **Internet Gateway** → **Internet**.
   - Allows direct internet access.

2. **Private Subnet Traffic Flow** (Uses a **NAT Gateway**):  
   - **Private Instance** → **Route Table** → **NAT Gateway** → **Internet Gateway** → **Internet**.
   - Allows outbound internet access while **blocking inbound access**.

---
# eip.tf
Let's break down the `eip.tf` file from both an **AWS perspective** and a **Terraform code perspective**.

---

## **AWS Perspective:**
The `eip.tf` file defines an **Elastic IP (EIP)**, which is a **static, public IP address** that can be assigned to AWS resources, such as a **NAT Gateway** or an **EC2 instance**.

### **Key Concepts:**
1. **Elastic IP (`aws_eip`)**:  
   - A **static public IPv4 address** assigned to AWS resources in a VPC.
   - Used primarily to provide a **consistent public IP** for internet access.
   - In this case, it is used for a **NAT Gateway**, enabling instances in a private subnet to access the internet.

2. **`vpc = true`**:  
   - This ensures that the **Elastic IP is allocated within the VPC**.
   - The IP can then be assigned to a **NAT Gateway**.

3. **`depends_on = [aws_internet_gateway.igw]`**:  
   - Ensures that the **Internet Gateway (IGW)** is created before the Elastic IP.
   - The **NAT Gateway**, which requires this EIP, needs an IGW to route traffic.

---

## **Terraform Code Perspective:**
### **1. `eip.tf`**
This file creates an **Elastic IP**.

```hcl
resource "aws_eip" "nat_eip" {
  vpc = true  # Allocate the EIP in the VPC

  depends_on = [aws_internet_gateway.igw]  # Ensure IGW is created first
}
```

### **Code Breakdown:**
- **`vpc = true`** → Allocates an Elastic IP **inside the VPC**.
- **`depends_on = [aws_internet_gateway.igw]`** → Ensures that the **IGW** is set up before allocating the EIP.

---

## **How This Fits into the Network:**
1. The **Elastic IP (EIP)** is **created and assigned** to the **NAT Gateway**.
2. The **NAT Gateway** (in a **public subnet**) uses this **static public IP** for outbound internet access.
3. Private subnet instances can now send outbound traffic via the **NAT Gateway**.

---

---
please explain the bellow files which are related to vpc module in terraform from and aws perspective to declare the concepts and from terraform code perspective also 
