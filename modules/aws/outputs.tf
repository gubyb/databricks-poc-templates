output "arn" {
  value = aws_iam_role.cross_account_role.arn
}

output "vpc_id" {
  value = aws_vpc.mainvpc.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat_gateways[0].id
}

output "backend_rest_pe" {
  value = aws_vpc_endpoint.backend_rest.id
}

output "backend_relay_pe" {
  value = aws_vpc_endpoint.backend_relay.id
}

output "aws_kms_key_manage_storage_arn" {
  value = aws_kms_key.managed_storage.arn
}

output "aws_kms_key_manage_storage_key_alias" {
  value = aws_kms_alias.managed_storage_key_alias.name
}

output "aws_kms_key_workspace_storage_arn" {
  value = aws_kms_key.workspace_storage.arn
}

output "aws_kms_key_workspace_storage_key_alias" {
  value = aws_kms_alias.workspace_storage_key_alias.name
}

output "cross_account_role" {
  value = aws_iam_role.cross_account_role.arn
}

output "cross_account_role_name" {
  value = aws_iam_role.cross_account_role.name
}

output "aws_sg_id" {
  value = aws_security_group.sg.id
}