terraform {
  backend "s3"{
    bucket                 = "pin-2-gh-terraform-aws-group13-tfstates"
    region                 = "us-east-1"
    key                    = "backend.tfstate"
    dynamodb_table         = "terraformstatelock"
  }
}