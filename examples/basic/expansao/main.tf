provider "aws" {
  region = "us-east-1"
}

module "organization" {
  source = "../../../"

  # Uncomment and set this if you already have an AWS Organization
   existing_organization_id = "r-d4hh"

  # You can add more OUs here, such as "security", "networking", "platform", etc.
  organizational_units = {
    rumolog = "Rumo Logistica"
    rumodominios = "Domínios Rumo"
    expansao      = "expansao"
  }

  organizational_unit_parents = {
    rumodominios  = "rumolog"
    expansao      = "rumodominios"
}

  accounts = {
    dev = {
      email      = "danielbarreeto+devexp@gmail.com"
      name       = "daniel-infra-dev-expansao"
      parent_key = "expansao"
    }

    qas = {
      email      = "danielbarreeto+qasexp@gmail.com"
      name       = "daniel-infra-qas-expansao"
      parent_key = "expansao"
    }

    prd = {
      email      = "danielbarreeto+prdexp@gmail.com"
      name       = "daniel-infra-prd-expansao"
      parent_key = "expansao"
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
