output "instance_id" {
  description = "Open EC2 instance ID in AWS Console and connect with Session Manager"
  value       = aws_instance.lab.id
}
output "public_ip" {
  description = "Public IP is for outbound network access; no inbound rules exist"
  value       = aws_instance.lab.public_ip
}
output "vpc_id" {
  value = aws_vpc.lab.id
}
output "ssm_hint" {
  value = "EC2 > Instances > select ${aws_instance.lab.id} > Connect > Session Manager"
}
