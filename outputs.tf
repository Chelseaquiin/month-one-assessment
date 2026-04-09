####################################
# OUTPUTS
####################################

output "vpc_id" {

  value = aws_vpc.techcorp_vpc.id

}

output "load_balancer_dns" {

  value = aws_lb.alb.dns_name

}

output "bastion_public_ip" {

  value = aws_instance.bastion.public_ip

}
