# TODO: replace this weith SSM access
# Createa a key-pair for EC2 access via SSH
resource "aws_key_pair" "server-key" {
  key_name   = "server-key"
  public_key = file("~/.ssh/id_rsa.pub")
}


# Store the private part of ssh key pair in parameter store so Ansible controller can access it
# TODO maybe we want to use KMS encryption here or at least comment on it

resource "aws_ssm_parameter" "server-private-key" {
  name  = "server-private-key"
  type  = "String"
  value = file("~/.ssh/id_rsa")
}

# TODO: Narrow down what roles this allows us to assume
resource "aws_iam_role" "ansible_controller_role" {
  name = "ansible_controller_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Policy to allow Ansible controller not to access ssh key
resource "aws_iam_role_policy" "ansible_controller_policy" {
  name = "ansible_controller_policy"
  role = aws_iam_role.ansible_controller_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ssm:DescribeParameters"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters"
        ]
        Resource = "${aws_ssm_parameter.server-private-key.arn}"
      }

    ]
  })
}