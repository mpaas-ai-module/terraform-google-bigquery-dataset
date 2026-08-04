terraform {
  required_version = ">=0.13"

  required_providers {
    # Reconciled with the published v1.0.2, which relaxed this from the exact
    # "4.1.0" this fork still carried. An exact 4.1.0 is unsatisfiable alongside
    # the base kms / folder-project modules (~> 6.41.0), so a project with a
    # BigQuery node could not even terraform init.
    google = {
      source  = "hashicorp/google"
      version = "~> 6.41"
    }
    # google_project_service_identity is a google-beta resource. v1.0.1/v1.0.2
    # used it without declaring the provider, leaving it to implicit inference.
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.41"
    }
  }
}
