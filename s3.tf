resource "aws_s3_bucket" "web_bucket" {
  bucket        = local.s3_bucket_name
  acl           = "private"
  force_destroy = true

  tags = local.common_tags

}

resource "aws_s3_bucket_object" "website" {
  for_each = {
    website = "/website/index.html"
    logo    = "/website/Globo_logo_Vert.png"
  }
  bucket = aws_s3_bucket.web_bucket.bucket
  key    = each.value
  source = ".${each.value}"

  tags = local.common_tags
}