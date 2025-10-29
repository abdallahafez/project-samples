
# **Regarding readme.md**  

#### **1. "Make sure you are in a directory outside modules and running Terraform as a user with AWS S3 CLI permissions."**  

- **Why "outside modules"?**  
  - In Terraform, **modules** are reusable configurations stored in a separate directory (e.g., `modules/s3_website`).  
  - You should **call the module from a main Terraform file** in the **root directory** (e.g., `main.tf`), rather than running `terraform apply` inside the `modules/` folder.

- **يمكنك التحقق من المستخدمين الذين لهم صلاحية لاستدعاء s3**  
 
```bash
    aws sts get-caller-identity
```
    This should return the IAM user who is executing Terraform.

---

#### **2. "Please change the below attributes as per your requirements: `s3_bucket_name`, `document_directory`, and `aws_profile_name` in the module section."**  
تحديد هذه المتغيرات بالقيمة التي تختارها , وهذا التحديد يكون بعدة طرق 
##### **1-  `terraform.tfvars`**
```hcl
s3_bucket_name     = "my-static-site-bucket"
document_directory = "/home/user/website-files"
aws_profile_name   = "default"
```
2- pass them via the command line:
```bash
terraform apply -var="s3_bucket_name=my-static-site-bucket" \
                -var="document_directory=/home/user/website-files" \
                -var="aws_profile_name=default"
```
3- during the runtime 

---

### **Understanding the Command**
* هذا اﻷمر يقوم بتنفيذ إعدادات التيرافورم الخاصة بموديول ولكن من خارج هذا الموديول بتعيينه في اﻷمر 
```bash
sudo terraform apply -target module.collabnix_static_s3_website -auto-approve
```
Let's break it down:

1. **`sudo`**  
   - Runs Terraform with superuser privileges.  
   - This might be required if files in `document_directory` need root access.

2. **`terraform apply`**  
   - Applies the Terraform configuration and provisions the defined resources.

3. **`-target module.collabnix_static_s3_website`**  
   - Targets **only this specific module** instead of applying all resources.
   - Useful for testing and debugging **one module at a time**.

4. **`-auto-approve`**  
   - Skips the confirmation prompt (`yes/no`) and **automatically applies** changes.  
   - Be careful with this, as it immediately provisions or destroys resources.


---
#######################################################################################################
# s3.tf comments 
### **1. Resource Definition**
```hcl
resource "aws_s3_bucket" "my_static_website_bucket" {
```
- This defines an **S3 bucket** using Terraform.
- The **resource type** is `aws_s3_bucket`, and the **logical name** is `my_static_website_bucket`.

### **2. Bucket Name**
```hcl
bucket = var.s3_bucket_name
```
- The bucket name is dynamically assigned using a Terraform **variable** (`var.s3_bucket_name`).
- You must define this variable elsewhere in your Terraform files (e.g., in a `variables.tf` or `.tfvars` or at the runtime file).

### **3. Access Control (ACL)**
```hcl
acl = "public-read"
```
- This makes the bucket **publicly readable**.
- This is necessary for hosting a public **static website** but may require an additional bucket policy.

### **4. Force Destroy**
```hcl
force_destroy = true
```
- Allows Terraform to **delete the bucket** even if it contains objects.
- If set to `false`, Terraform will fail to destroy the bucket if it's not empty.

### **5. Tags**
```hcl
tags = {
  project = "Collabnix"
  department = "Automation"
}
```
- Adds metadata (tags) to the bucket, which can be useful for **organization and cost tracking**.

---

## **Static Website Hosting Configuration**
The following block enables **S3 static website hosting**:

```hcl
website {
  index_document = "index.html"
  error_document = "error.html"
```
- Defines the **default document** (`index.html`) for the website.
- Specifies an **error page** (`error.html`).

### **Routing Rules**
```hcl
routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF
```
- **Routing rules** define how S3 should handle specific URL patterns.
- Here, if a user requests a file under `docs/`, it redirects them to `documents/`.
- Example:
  - `https://mybucket.s3-website-us-east-1.amazonaws.com/docs/file.html`
  - Redirects to:
  - `https://mybucket.s3-website-us-east-1.amazonaws.com/documents/file.html`

---

## **Provisioner (File Upload Automation)**
```hcl
provisioner "local-exec" {
  command = "aws s3 cp ${var.document_directory} s3://${var.s3_bucket_name}/ --exclude \"*\" --include \"*.html\" --recursive --profile ${var.aws_profile_name} --acl public-read"
}
```
### **Understanding `provisioner "local-exec"` in Terraform**  

The **`local-exec` provisioner** :يتم استخدامه لإجراء بعض اﻷوامر على الجهاز المحلي وعادتا ما يكون تنفيذ هذه اﻷوامر بعد إنشاء الريسورس 

```hcl
provisioner "local-exec" {
  command = "aws s3 cp ${var.document_directory} s3://${var.s3_bucket_name}/ --exclude \"*\" --include \"*.html\" --recursive --profile ${var.aws_profile_name} --acl public-read"
}
```
executes a command that **uploads files to an S3 bucket** using the AWS CLI.

---

## **Breaking Down the Command**
Let's analyze the command inside `local-exec`:

```bash
aws s3 cp ${var.document_directory} s3://${var.s3_bucket_name}/ \
    --exclude "*" --include "*.html" --recursive \
    --profile ${var.aws_profile_name} --acl public-read
```

| Component | Description |
|-----------|------------|
| `aws s3 cp` | AWS CLI command to copy (`cp`) files from local to S3. |
| `${var.document_directory}` | The **local directory** containing the HTML files (defined as a Terraform variable). |
| `s3://${var.s3_bucket_name}/` | The **destination S3 bucket** (dynamic, set using a Terraform variable). |
| `--exclude "*"` | Excludes **all files** by default. |
| `--include "*.html"` | Includes only **`.html`** files for upload. |
| `--recursive` | Ensures that **all `.html` files** in subdirectories are also uploaded. |
| `--profile ${var.aws_profile_name}` | Specifies the AWS **credentials profile** (set dynamically). |
| `--acl public-read` | Makes uploaded files **publicly readable**. |

---



### **The Command Terraform Executes:**
```bash
aws s3 cp /home/user/website-files s3://my-static-site-bucket/ \
    --exclude "*" --include "*.html" --recursive \
    --profile default --acl public-read
```

### **What This Does:**
- Uploads **all `.html` files** from `/home/user/website-files` to `s3://my-static-site-bucket/`.
- Files are **made publicly accessible** (`public-read` ACL).
- Only **HTML files** are uploaded (other files like `.css` and `.js` are ignored).
- Uses the **AWS credentials profile** named `default`.

---

## **When Does Terraform Run This Provisioner?**
- The `local-exec` provisioner runs **on the machine executing Terraform** (not on AWS).  
- It runs **after Terraform creates the S3 bucket**.  
- If the bucket already exists and no changes are made to the Terraform config, this provisioner **will not run again** unless the bucket resource is re-created.

---

## **Key Considerations**

🔹 **Alternatives to `local-exec`**
- Instead of `local-exec`, you can use **AWS S3 Sync** manually:
  ```bash
  aws s3 sync /home/user/website-files s3://my-static-site-bucket/ --acl public-read
  ```

---

####################################################################################
# output.tf 
يستخدم هذا الملف **لعرض معلومات هامة** بعد تنيفذ التعليمات في ملف التيرافورم 
 it provides the S3 bucket's <span style="color:red;">website endpoint</span> and its <span style="color:red;">regional domain name.</span>

---
في البداية لنأخذ فكرة عن هذين المصطلحين في S3 :

### **Understanding `website_endpoint` and `bucket_regional_domain_name` in S3**  

When you create an **Amazon S3 bucket**, Terraform provides different attributes that allow you to access the bucket in different ways. Two important attributes are:  

1. **`website_endpoint`** → Used for accessing a static website hosted on S3.  
2. **`bucket_regional_domain_name`** → Used for direct API access to the bucket.  

---

## **1. `website_endpoint` (Used for Static Website Hosting)**
- This attribute provides the **URL for accessing an S3 bucket as a static website**.  
- It is available **only if you enable "Static Website Hosting"** in your S3 bucket settings.  
- The format of the `website_endpoint` depends on the AWS region.

### **Example Format:**
```
http://<bucket-name>.s3-website-<region>.amazonaws.com
```

### **Example Output (for `us-east-1` region)**
```bash
website_endpoint = "http://my-static-site.s3-website-us-east-1.amazonaws.com"
```

### **Usage:**
- Used when you host a **static website** (HTML, CSS, JS) in S3.  
- If you enter this URL in a browser, you can see your website.  
- It does **not support HTTPS** (AWS recommends using CloudFront for HTTPS).  

---

## **2. `bucket_regional_domain_name` (Used for API and SDK Access)**
- This attribute provides the **region-specific domain name** for the S3 bucket.  
- It is used when you need to access the bucket via **AWS SDK, CLI, or APIs**.  
- The format is **different from `website_endpoint`**.

### **Example Format:**
```
<bucket-name>.s3.<region>.amazonaws.com
```

### **Example Output (for `us-east-1` region)**
```bash
bucket_regional_domain_name = "my-static-site.s3.us-east-1.amazonaws.com"
```

### **Usage:**
- Used when integrating **CloudFront** with S3 (CloudFront prefers regional endpoints).
- Used in **AWS SDKs** and CLI commands:
  ```bash
  aws s3 ls s3://my-static-site --endpoint-url https://my-static-site.s3.us-east-1.amazonaws.com
  ```

---

## **Key Differences:**
| Attribute | Purpose | Supports HTTPS? | Example Format |
|-----------|---------|----------------|----------------|
| **`website_endpoint`** | Used for static website hosting | ❌ No | `http://my-bucket.s3-website-us-east-1.amazonaws.com` |
| **`bucket_regional_domain_name`** | Used for API, SDK, and CloudFront | ✅ Yes | `my-bucket.s3.us-east-1.amazonaws.com` |

---

## **Which One Should You Use?**
- **If you are hosting a static website** → Use `website_endpoint`  
- **If you are accessing the bucket via SDK, CLI, or CloudFront** → Use `bucket_regional_domain_name`  

Would you like to see an example using **CloudFront** to enable HTTPS for your S3 website? 🚀
#################################
## **Breaking Down the File**  

### **1. First Output: `bucket_domain_name`**
```hcl
output "bucket_domain_name" {
  value = aws_s3_bucket.my_static_website_bucket.website_endpoint
}
```
- **What it does:**  
  - This outputs the **S3 static website URL** after Terraform applies the configuration.  
  - The value is retrieved from the `website_endpoint` attribute of the **S3 bucket resource** (`aws_s3_bucket.my_static_website_bucket`).

- **Example Output (if the bucket is in `us-east-1`):**  
  ```text
  bucket_domain_name = "http://my-static-site-bucket.s3-website-us-east-1.amazonaws.com"
  ```
- **Usage:**  
  - This URL is used to **access the static website** hosted in the S3 bucket.

---

### **2. Second Output: `this_s3_bucket_bucket_regional_domain_name`**
```hcl
output "this_s3_bucket_bucket_regional_domain_name" {
  description = "The bucket region-specific domain name. The bucket domain name including the region name, please refer here for format. Note: The AWS CloudFront allows specifying S3 region-specific endpoint when creating S3 origin, it will prevent redirect issues from CloudFront to S3 Origin URL."
  value       = aws_s3_bucket.my_static_website_bucket.bucket_regional_domain_name
}
```
- **What it does:**  
  - Outputs the **regional domain name** of the S3 bucket.  
  - This is useful when integrating the bucket with **CloudFront** (AWS CDN).

- **Example Output (if the bucket is in `us-east-1`):**  
  ```text
  this_s3_bucket_bucket_regional_domain_name = "my-static-site-bucket.s3.us-east-1.amazonaws.com"
  ```
- **Usage:**  
  - This is useful when configuring **CloudFront** as the origin, since CloudFront prefers the regional domain name.

---
