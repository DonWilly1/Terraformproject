output "region" {
  value = var.region
}

output "project_name" {
  value = var.project_name
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "web_public_subnet-1_id" {
  value = aws_subnet.web_public_subnet-1.id
}

output "web_public_subnet-2_id" {
  value = aws_subnet.web_public_subnet-1.id
}

output "priv_app_subnet-1_id" {
  value = aws_subnet.priv_app_subnet-1.id
}

output "priv_app_subnet-2_id" {
  value = aws_subnet.priv_app_subnet-2.id
}

output "Prod-igw" {
  value = aws_internet_gateway.Prod_igw
}

