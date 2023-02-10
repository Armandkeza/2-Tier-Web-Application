#Random ID for unique naming
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}
locals {
  common_tags = {
    company      = var.company
    project      = "${var.company}-${var.project}"
  }
  name_prefix    = "${var.naming_prefix}-webapp"
  subnet1 = cidrsubnet(var.vpc_cidr_block, 8, 3)
  subnet2 = cidrsubnet(var.vpc_cidr_block, 8, 4)
  s3_bucket_name = lower("${local.name_prefix}-${random_integer.rand.result}")
}
