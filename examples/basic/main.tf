provider "aws" {
  region = "us-east-1"
}

module "organization" {
  source = "../../"

  # Uncomment and set this if you already have an AWS Organization
   existing_organization_id = "r-d4hh"

  # You can add more OUs here, such as "security", "networking", "platform", etc.
  organizational_units = {
    infrastructure = "Infrastructure"
    # security     = "Security"
    # networking   = "Networking"
    platform     = "Platform"
    contas = "Contas"
    new-account = "new-account"
  }

  accounts = {
    dev = {
      email      = "danielbarreeto+dev@gmail.com"
      name       = "daniel-infra-dev"
      parent_key = "platform/contas/new-account"
    }

    qas = {
      email      = "danielbarreeto+qas@gmail.com"
      name       = "daniel-infra-qas"
      parent_key = "platform/contas/new-account"
    }

    prd = {
      email      = "danielbarreeto+prd@gmail.com"
      name       = "daniel-infra-prd"
      parent_key = "platform/contas/new-account"
    }
  }

  tags = {
    Provisioning-method = "terraform"
    Environment = "orgsetup"
  }

  # aws_service_access_principals = [
  #   "sso.amazonaws.com",
  #   "health.amazonaws.com"
  # ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]

  feature_set = "ALL"
}
