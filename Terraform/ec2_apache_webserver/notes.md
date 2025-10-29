
# ec2.tf
### تم توضيح معظم هذه الإعدادات سابقا وسيتم توضيح جزء واحد فقط وهو ال provisioner 

### **Breakdown of Terraform Provisioners in `ec2.tf`**  

In your `ec2.tf` file, Terraform uses **provisioners** to configure the EC2 instance after it's created. These provisioners do two things:  
1. **Upload a script (`bootscript.sh`) to the EC2 instance** using the `file` provisioner.  
2. **Make the script executable and run it** using the `remote-exec` provisioner.  

---

## **1️⃣ File Provisioner** (Uploads Script to EC2)
```hcl
provisioner "file" {
  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/key.pem")
  }

  source      = var.bootscript_file_path
  destination = "/tmp/bootscript.sh"
}
```

### **🔍 Explanation**
- **Purpose**: Transfers a local script (`bootscript.sh`) to `/tmp/bootscript.sh` inside the EC2 instance.  
- **`connection` block**:
  - Uses **SSH** to connect to the EC2 instance.
  - **`host = self.public_ip`** → Connects via the **instance's public IP**.
  - **`private_key = file("${path.module}/key.pem")`** → Uses an SSH key for authentication.
- **File Transfer**:
  - **`source = var.bootscript_file_path`** → Local file path of the script.
  - **`destination = "/tmp/bootscript.sh"`** → Target location in the EC2 instance.

---

## **2️⃣ Remote-Exec Provisioner** (Runs the Script)
```hcl
provisioner "remote-exec" {
  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/key.pem")
  }

  inline = [
    "chmod +x /tmp/bootscript.sh",
    "/tmp/bootscript.sh",
  ]
}
```

### **🔍 Explanation**
- **Purpose**: Runs commands **inside** the EC2 instance after the script is uploaded.
- **`inline` block**:
  - **`chmod +x /tmp/bootscript.sh`** → Makes the script executable.
  - **`/tmp/bootscript.sh`** → Executes the script.

---
                                                                                                                           
---

