resource "aws_vpc_endpoint" "eks-endpoints" {
   for_each = toset(local.service)

   region = var.region
   vpc_id = var.vpc_id
   service_name = "com.amazonaws.${var.region}.${each.value}"
   vpc_endpoint_type = "Interface"
   subnet_ids = var.subnet_ids
   tags = merge(var.tags, {
     Name = "eks-endpoints-${each.value}"
   })
}