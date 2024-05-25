module "ou-account" {
  source = "../"
  ou_map = yamldecode(file("${path.module}/ou_acc.yaml"))
  python = "python"
}

output "op" {
  value = module.ou-account
}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.45"
    }
  }
  required_version = ">= 1.8.0"
}
