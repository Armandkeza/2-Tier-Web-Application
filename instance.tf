##################################################################################
# DATA
##################################################################################

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_launch_configuration" "Brainwork" {
  name_prefix     = "${local.name_prefix}-launchconfig"
  image_id        = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.Brainwork-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  depends_on             = [aws_iam_role_policy.allow_s3_all]
  
  user_data = templatefile("${path.module}/startup_script.tpl", {
    s3_bucket_name = aws_s3_bucket.web_bucket.id
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "Brainwork" {
  name                 = "${local.name_prefix}-asg"
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.Brainwork.name
  vpc_zone_identifier  = aws_subnet.private-subnets[*].id
  

}



