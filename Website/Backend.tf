# store the terraform state file in s3 and lock with dynamodb
terraform {
  backend "s3" {
    bucket         = "donwilly"
    key            = "DynamoDB/*  */.tfstate"
    region         = "eu-west-2"
  }
}