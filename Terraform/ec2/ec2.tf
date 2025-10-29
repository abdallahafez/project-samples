data "aws_ami" "hafez_query" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
# filter added by hafez to select 64 bit
filter {
  name   = "architecture"
  values = ["x86_64"] # or "arm64"
}

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "instance" {
  #ami           = data.aws_ami.ubuntu.id
  ami           = data.aws_ami.hafez_query.id
  instance_type = "t2.micro"
  key_name = var.key_pair_name

  network_interface {
    network_interface_id = aws_network_interface.defaultNIC.id
    device_index         = 0
  }

  tags = {
    project = "Collabnix"
    department = "Automation"
  }
}
