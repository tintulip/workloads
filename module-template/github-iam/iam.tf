resource "aws_iam_user" "user" {
  force_destroy = "false"
  name          = var.user
  path          = "/"

}


data "aws_caller_identity" "current" {}

resource "aws_iam_role" "role" {
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": ["sts:AssumeRole","sts:TagSession"],
      "Condition": {},
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.user}"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY


  description          = "for usage by the tf stack and pipeline creating the ${var.user} "
  max_session_duration = "3600"
  name                 = var.user
  path                 = "/"


}

resource "aws_iam_user_policy" "user_policy" {
  #checkov:skip=CKV_AWS_40:only the user is allowed to assume the role
  name = var.user
  user = aws_iam_user.user.name


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole", "sts:TagSession"
        ]
        Effect   = "Allow"
        Resource = aws_iam_role.role.arn
      },
    ]
  })
}

resource "aws_iam_access_key" "user_key" {
  user    = aws_iam_user.user.name
  pgp_key = var.gpg_key
}