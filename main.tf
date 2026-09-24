data "google_project" "current" {
  project_id = var.project_id
}

data "google_kms_key_ring" "project_keyring" {
  project  = var.project_id
  name     = var.project_id
  location = var.location
}

data "google_kms_crypto_key" "project_key" {
  name     = "${data.google_project.current.name}-key"
  key_ring = data.google_kms_key_ring.project_keyring.id
}

resource "google_project_service" "bigquery" {
  project            = var.project_id
  service            = "bigquery.googleapis.com"
  disable_on_destroy = false
}

data "google_bigquery_default_service_account" "bq_sa" {
  project    = var.project_id
  depends_on = [google_project_service.bigquery]
}

resource "time_sleep" "wait_for_sa" {
  create_duration = "60s"

  depends_on = [
    data.google_bigquery_default_service_account.bq_sa
  ]
}

resource "google_kms_crypto_key_iam_member" "bq_cmek" {
  crypto_key_id = data.google_kms_crypto_key.project_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_bigquery_default_service_account.bq_sa.email}"

  depends_on = [
    time_sleep.wait_for_sa
  ]

  lifecycle {
    ignore_changes = [member]
  }
}

resource "google_bigquery_dataset" "dataset" {
  project    = var.project_id
  count      = var.no_of_datasets
  dataset_id = var.dataset_name[count.index]
  location   = var.location

  default_encryption_configuration {
    kms_key_name = data.google_kms_crypto_key.project_key.id
  }

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }

  depends_on = [
    google_kms_crypto_key_iam_member.bq_cmek
  ]
}