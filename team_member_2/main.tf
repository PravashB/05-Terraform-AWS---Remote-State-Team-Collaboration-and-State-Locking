resource "aws_s3_bucket" "member2_bucket" {
  bucket = "team-member-2-bucket-pro-${random_integer.suffix.result}"

  tags = {
    Name = "TeamMember2Bucket"
  }
}

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}
