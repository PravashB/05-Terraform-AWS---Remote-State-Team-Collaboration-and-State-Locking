resource "aws_s3_bucket" "member1_bucket" {
  bucket = "team-member-1-bucket-pro-${random_integer.suffix.result}"

  tags = {
    Name = "TeamMember1Bucket"
  }
}

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}
