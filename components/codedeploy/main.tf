resource "aws_codedeploy_app" "this" {
  compute_platform = "ECS"
  name             = var.service_name
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = aws_codedeploy_app.this.name
  deployment_group_name  = var.service_name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = var.role_arn

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.service_name
  }

}