# Command to get the private key once host is running
# aws ssm get-parameters --name "server-private-key" | jq -r '.Parameters[0].Value'

# Intance profile and role for Ansible controller
# TODO switch up to _ based nameing instaed of - 
resource "aws_iam_instance_profile" "ansible_controller_instance_profile" {
  name = "ansible_controller_instance_profile"
  role = aws_iam_role.ansible_controller_role.name
}

# TODO: Try to make a constant file for the instance type
# TODO: Can we make sure that Ansible host is first to be created?
resource "aws_instance" "ansible-controller" {
  ami                         = data.aws_ami.centos_8_ami.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.server-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id
  iam_instance_profile        = aws_iam_instance_profile.ansible_controller_instance_profile.id
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install epel-release ",
      "sudo yum -y install ansible",
      "sudo yum -y install unzip",
      "sudo yum -y install jq",
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
      "unzip awscliv2.zip",
      "sudo ./aws/install"
    ]
    connection {
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  tags = {
    Name = "Ansible Controller"
  }
}

variable "test_instance_count" {
  default = "1"
}

resource "aws_instance" "test-host-1" {
  count                       = var.test_instance_count
  ami                         = data.aws_ami.centos_8_ami.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.server-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id
  tags = {
    Name = "Test Host ${count.index + 1}"
  }
}

# resource "aws_instance" "test-host-2" {
#   ami                         = data.aws_ssm_parameter.server-ami.value
#   instance_type               = "t3.micro"
#   key_name                    = aws_key_pair.server-key.key_name
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.sg.id]
#   subnet_id                   = aws_subnet.subnet.id
#   tags = {
#     Name = "Test Host 2"
#   }
# }