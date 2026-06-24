resource "google_bigquery_dataset" "dataset" {
  project                     = var.project_id 
  count                       = var.no_of_datasets
  dataset_id                  = var.dataset_name[count.index] 
  location                    = var.location
  default_encryption_configuration {
    kms_key_name = var.kms_key_name
  }
  lifecycle {
     ignore_changes = [
# Ignore changes to tags, e.g. because a management agent
# updates these based on some ruleset managed elsewhere.
          labels,
 ]
 }
  depends_on = [ google_project_iam_binding.network_binding3 ]
}
 data "google_project" "service_project2" {
  project_id = var.project_id
}
resource "google_project_iam_binding" "network_binding3" {
  count   = 1
  project = var.project_id
  lifecycle {
    ignore_changes = [ members ]
  }
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:bq-${data.google_project.service_project2.number}@bigquery-encryption.iam.gserviceaccount.com",
  ]
}


