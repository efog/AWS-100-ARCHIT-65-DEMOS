output "public_subnet_a_id" {
  value = "${aws_subnet.public_subnet_a.id}"
}

output "public_subnet_b_id" {
  value = "${aws_subnet.public_subnet_b.id}"
}

output "private_subnet_a_id" {
  value = "${aws_subnet.private_subnet_a.id}"
}

output "private_subnet_b_id" {
  value = "${aws_subnet.private_subnet_b.id}"
}

output "vpc_id" {
  value = "${aws_vpc.base_vpc.id}"
}

output "alb_arn" {
  value = "${aws_lb.application_load_balancer.arn}"
}

output "subnets" {
  value = ["${aws_subnet.private_subnet_a.id}","${aws_subnet.private_subnet_b.id}"]
}

output "security_groups" {
  value = ["${aws_security_group.web_security_group.id}"]
}