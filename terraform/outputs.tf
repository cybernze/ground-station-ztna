output "server_public_ip" {
  description = "Public IP of the Ground Station EC2 instance"
  value       = aws_instance.ground_station.public_ip
}

output "ssh_command" {
  description = "Ready-to-use SSH command"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.ground_station.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}
