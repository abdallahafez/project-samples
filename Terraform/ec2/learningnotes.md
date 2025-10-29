* will start with my provider.tf 
```bash
provider "aws" {
    profile = "default" 
    region = "eu-west-1" 
```

* skip the modules for now but this is the ec2 module
```bash
module "collabnix_ec2" {
  source = "./modules/ec2"
  public_subnet = module.collabnix_vpc.public_subnet_id
}
``` 
* start with ec2 
  * start with variable.tf 
```bash
variable "public_subnet" {}

variable "key_pair_name" {
   description =   "Key_Pair_Name"
   type        =   string
   default = "keypair"
}
```
    *   keypair.tf 
```bash
resource "aws_key_pair" "keypair" {
  key_name   = var.key_pair_name
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKM1m3gIRU8G0O8oOUN8K9i9qV2DW6K+4/M/jmdYq4D150oB4DFaycCQhVjYsPNTsPCCaLum/dmgh9nJw3XGkMDzrg3+JKwFltxPtWId50pZlVbVXdqEiKE7jMAvdkS3D17e3cZ+hJ21P7SrnLbsNGs3lRcOhfaTwZsPuiV2YZuSijcsmCnq2dyRsQCqxJ9tKkhZL/H/HlnwEGSJuu3o76gkWdHvbSPpJJQ2W+pBx54CUmpSKFOUTYyOtw9ZXB0j0PhgKlWv26p1IABZodxFxZiiRg0ZOrYKMyI9uYQ1hcIzcqtssYMgXKbR5JbPzo+S2ef6DbZQeKvT/q6AsKH6Gv"
}
```








Let’s break down each file and its components in detail:

---

### **1. `variables.tf` File**
#### **Variable: `public_subnet`**
```terraform
variable "public_subnet" {}
```
  - **No Default Value**: It has no `default`, so you **must provide a value** when calling this module (e.g., from `main.tf`).
  - **Usage**: Likely passed to the EC2 instance to specify its network placement.

#### **Variable: `key_pair_name`**
```terraform
variable "key_pair_name" {
  description = "Key_Pair_Name"
  type        = string
  default     = "keypair"
}
```
- **Purpose**: Defines the name of the AWS key pair used for SSH access to the EC2 instance.
  - **`default`**: If no value is provided when using this module, Terraform will use `"keypair"` as the default name.
---

### **2. `keypair.tf` File**
#### **Resource: `aws_key_pair`**
```terraform
resource "aws_key_pair" "keypair" {
  key_name   = var.key_pair_name
  public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
}
```
- **Purpose**: Creates an **AWS key pair** to allow SSH access to the EC2 instance.
- لاحظ أن وظيفة هذا الريسورس أن يقوم بالرفع الى امازون حيث أن المفتاح موجود مسبقا وما يجري فقط هو رفعه
- **Breakdown**:
  1. **`resource "aws_key_pair" "keypair"`**:
     - Declares an AWS key pair resource named `keypair` (internal Terraform name).
     - The AWS console will show this key pair with the name specified in `key_name`.

  2. **`key_name = var.key_pair_name`**:
     - Sets the name of the key pair in AWS to the value of the `key_pair_name` variable.
     - If no value is provided, it defaults to `"keypair"` (from `variables.tf`).

  3. **`public_key = "ssh-rsa AAAAB3NzaC1yc2E..."`**:
     - Specifies the **public key** to upload to AWS. This is the key you’ll use to SSH into the EC2 instance.
     - The long string is the actual public key (truncated here for brevity).

---
#### لاحظ أن كتابة المفتاح في الكود بهذا الشكل ليس الخيار اﻷفضل 
- **Hardcoded Key**: The public key is hardcoded directly in the Terraform file.  
  **Best Practice**: Store the public key in a separate file (e.g., `public.pem`) and reference it using Terraform’s `file()` function:
  ```terraform
  public_key = file("${path.module}/public.pem")
  ```
- **Private Key**: Ensure the corresponding **private key** (`key.pem` in your directory) is **never committed to version control** (add it to `.gitignore`).


---
---



# `ec2.tf`

---

### **1. Data Source: `aws_ami` (Ubuntu AMI Lookup)**

| Part              | Explanation                                                                                   |
|--------------------|-----------------------------------------------------------------------------------------------|
| `data`             | Indicates this is a **data source** (used to fetch information from the provider, e.g., AWS). |
| `aws_ami`          | The **type of data source** (specific to AWS for querying AMIs).                             |
| `ubuntu`           | The **local name** given to this specific data source block (user-defined).                   |
| `id`               | An **attribute** of the `aws_ami` data source that returns the AMI ID.                       |

---

### **2. How It Works**
- **Data Source Block**:
  ```terraform
  data "aws_ami" "ubuntu" {
    most_recent = true
    # ... filters ...
  }
  ```
  - Terraform uses this block to query AWS for the latest Ubuntu AMI matching your filters.

- **`id` Attribute**:
  - Every `aws_ami` data source exposes an `id` attribute, which contains the **AMI ID** (e.g., `ami-0c55b159cbfafe1f0`).
  - This is the unique identifier for the AMI, required when launching an EC2 instance.

- **Reference Syntax**:
  - `data.aws_ami.ubuntu` refers to the entire data source block.
  - `.id` accesses the specific attribute (AMI ID) from the data source's result.

---

### **3. Key Concepts**
#### **Data Source vs. Variable**
- **Data Source**:
  - Fetches **dynamic, runtime information** from the provider (AWS).
  - Evaluated during `terraform apply` (not stored in memory permanently).
  - Example: Querying the latest AMI ID.
- **Variable**:
  - Defined in `variables.tf` and passed by users or modules.
  - Static input (e.g., `instance_type = "t2.micro"`).

#### **Why Use `id`?**
- The `id` is a predefined attribute of the `aws_ami` data source. Other attributes include:
  - `name`: The AMI name (e.g., `ubuntu-xenial-16.04-amd64-server-20240213`).
  - `creation_date`: When the AMI was created.
  - `root_device_type`: The storage type (e.g., `ebs`).


---
### **2. Resource: `aws_instance` (EC2 Instance)**
```terraform
resource "aws_instance" "instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_pair_name
  network_interface {
    network_interface_id = aws_network_interface.defaultNIC.id
    device_index         = 0
  }
  tags = {
    project    = "Collabnix"
    department = "Automation"
  }
}
```
- **Purpose**: Creates an EC2 instance with specific configurations.
- **Key Components**:
  1. **`ami = data.aws_ami.ubuntu.id`**:
     - Uses the AMI ID fetched by the `aws_ami` data source (Ubuntu 16.04).
     - **`data.aws_ami.ubuntu.id`** references the `id` attribute of the `aws_ami` data source.

  2. **`instance_type = "t2.micro"`**:
     - Specifies the instance type as `t2.micro` (AWS free-tier eligible).
     - **Hardcoded Value**: Consider using a variable (e.g., `var.instance_type`) for flexibility.

  3. **`key_name = var.key_pair_name`**:
     - Associates the EC2 instance with the SSH key pair created in `keypair.tf`.
     - لاحظ انه تم تعيين الاسم على امازون وليس اسم تيرافورم 
     - The key pair name comes from the `key_pair_name` variable (default: `"keypair"`).

  4. **`network_interface` Block**:
     - **`network_interface_id`**: Attaches a network interface (NIC) defined in `networkinterface.tf` (referenced via `aws_network_interface.defaultNIC.id`).
     - **`device_index = 0`**: Designates this NIC as the primary network interface (eth0).

  5. **`tags`**:
     - Adds metadata tags to the EC2 instance for easy identification in the AWS Console.
     - Example tags: `project = "Collabnix"`, `department = "Automation"`.
---
---
# networkinterface.tf 

### **Explanation of `networkinterface.tf` and `ec2.tf` in Terraform**

---

## **1. `networkinterface.tf` - Creating a Network Interface**
This file defines an **AWS Network Interface (ENI - Elastic Network Interface)**.

```hcl
resource "aws_network_interface" "defaultNIC" {
  subnet_id = var.public_subnet

  tags = {
    project = "Collabnix"
    department = "Automation"
  }
}
```

### **Breaking It Down:**
هذا الجزء يقوم بتعريف الانترفيس والحاقها ب subnet
تم تعريفها مسبقا بالاسم
- `resource "aws_network_interface" "defaultNIC"`  
  → Defines a new **Elastic Network Interface (ENI)** in AWS and assigns it a Terraform identifier (`defaultNIC`).
  
- `subnet_id = var.public_subnet`  
  → Specifies which **subnet** the network interface will be created in.  
  → `var.public_subnet` is a Terraform **variable**, meaning this subnet is defined elsewhere (e.g., `variables.tf`).

- `tags`  
  → AWS tags help organize resources. In this case:  
  - `"project" = "Collabnix"` (Project name)  
  - `"department" = "Automation"` (Department using this resource)

#### **What this does?**
- Creates an independent **network interface** (ENI) in a specified **public subnet**.

---

## **2. `ec2.tf` - Attaching the Network Interface to an EC2 Instance**
This snippet is from `ec2.tf`, where an EC2 instance is defined.

```hcl
network_interface {
  network_interface_id = aws_network_interface.defaultNIC.id
  device_index         = 0
}
```

### **Breaking It Down:**
هذا الجزء يقوم بالحاق الانترفيس بلماكنة وهذه الانترفي تم انشاؤها مسبقا 
- `network_interface {}`  
  → This block **attaches** a **pre-existing** network interface (`defaultNIC`) to an **EC2 instance**.

- `network_interface_id = aws_network_interface.defaultNIC.id`  
  → The EC2 instance will use the network interface created earlier in `networkinterface.tf`.

- `device_index = 0`  
  → Specifies that this is the **primary network interface** (device index `0` is the first/default interface for an instance).

#### **What this does?**
- Ensures the EC2 instance **does not use the default network interface** assigned by AWS but instead attaches the **custom ENI** created earlier.

---

## **Summary:**
| File | Resource | Purpose |
|------|----------|---------|
| `networkinterface.tf` | `aws_network_interface.defaultNIC` | Creates a **custom network interface** in a **public subnet** |
| `ec2.tf` | `network_interface` block | Attaches the **custom ENI** to an EC2 instance |



