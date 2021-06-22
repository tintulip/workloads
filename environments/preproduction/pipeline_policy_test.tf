# Attempt to use local-exec provisioner
resource "aws_instance" "web" {
  #checkov:skip=CKV_AWS_126: For test purposes, ignore checkov checks
  #checkov:skip=CKV_AWS_135: For test purposes, ignore checkov checks
  #checkov:skip=CKV_AWS_79: For test purposes, ignore checkov checks
  #checkov:skip=CKV_AWS_8: For test purposes, ignore checkov checks
  #checkov:skip=CKV2_AWS_17: For test purposes, ignore checkov checks
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"
  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }
}

module "pipeline_policy_test" {
  source = "../../module-template/policy-test"
}

resource "null_resource" "example" {
  provisioner "local-exec" {
    command = "echo Hello World"
  }
}