terraform {
  backend "s3" {
    bucket         = "terraform-bootstrap-pro-lab"
    key            = "projects/sample-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-pro-lab"
    encrypt        = true
  }
}