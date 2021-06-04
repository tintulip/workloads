resource "aws_codedeploy_app" "this" {
  compute_platform = "ECS"
  name             = local.service_name
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = aws_codedeploy_app.this.name
  deployment_group_name  = local.service_name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy.arn

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.workloads.name
    service_name = aws_ecs_service.web_application.name
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.web_application.arn]
      }

      target_group {
        name = aws_lb_target_group.web_application.*.name[0]
      }

      target_group {
        name = aws_lb_target_group.web_application.*.name[1]
      }
    }
  }
}