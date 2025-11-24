output "vpc_id" {
  value = aws_vpc.techcorp_vpc.id

}

output "Bastion_ip" {
  value = aws_instance.bastion.public_ip
}


output "DNS" {
  value = aws_lb.alb.dns_name

}
output "db_server" {
  value = aws_instance.db_server.private_ip

}
