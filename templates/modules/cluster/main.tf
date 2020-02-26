resource "aws_ecs_cluster" "web_cluster" {
  name               = "web-cluster"
  capacity_providers = ["FARGATE"]
  tags               = "${var.tags}"
}
resource "aws_ecs_task_definition" "web_app" {
  family                   = "web_app_task"
  container_definitions    = file("./modules/cluster/tasks/web_app.json")
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  tags                     = "${var.tags}"
}

data "aws_lb" "web_alb" {
  arn = "${var.alb_arn}"
}

resource "aws_lb_target_group" "web_app_tg" {
  name        = "web-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = 80
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }
}
resource "aws_lb_listener" "web_app_listener" {
  load_balancer_arn = "${data.aws_lb.web_alb.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.web_app_tg.arn}"
  }
}

resource "aws_ecs_service" "web_app_svc" {
  name            = "web_app_svc"
  cluster         = "${aws_ecs_cluster.web_cluster.id}"
  task_definition = "${aws_ecs_task_definition.web_app.arn}"
  desired_count   = 3
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.web_app_tg.arn}"
    container_name   = "static-website"
    container_port   = 80
  }

  network_configuration {
    assign_public_ip = false
    subnets          = "${var.subnets}"
    security_groups  = "${var.security_groups}"
  }
}