# Attempt to use local-exec provisioner
resource "aws_instance" "web" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"
  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }
}

locals {
  production_account_id = "073232250817"
}

# Attempt to create a role that can be assumed by prod account
data "aws_iam_policy_document" "assume_by_prod" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.production_account_id}:root"]
    }
  }
}

resource "aws_iam_role" "role_to_be_assumed" {
  name               = "prod_role_assumer"
  assume_role_policy = data.aws_iam_policy_document.assume_by_prod.json
}