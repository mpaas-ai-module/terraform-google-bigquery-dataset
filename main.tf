###############################################################################
# BigQuery dataset(s) with CMEK.
#
# Reconciled against the PUBLISHED artifact (mpaas-ai-module/bigquery-dataset/
# google v1.0.2) — this fork had drifted behind it. The registry copy is the
# source of truth for what actually runs.
#
# The CMEK key grant deliberately does NOT live here any more. v1.0.2 had:
#
#   resource "google_project_iam_binding" "network_binding3" {
#     role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#     members = ["serviceAccount:bq-${data.google_project…number}@bigquery-encryption…"]
#   }
#
# which was wrong twice over:
#
#  1. The email was INTERPOLATED from the project number, naming an account that
#     need not exist. The BigQuery *encryption* agent is created lazily — only
#     when GCP is asked for it (bigquery.projects.getServiceAccount) — so on a
#     fresh project the first apply died with:
#       Error 400: Service account bq-<num>@bigquery-encryption.iam.gserviceaccount.com
#       does not exist., badRequest
#
#  2. google_project_iam_binding is AUTHORITATIVE for the role across the whole
#     project: applying it REPLACES every other member of
#     roles/cloudkms.cryptoKeyEncrypterDecrypter. The GCS, Cloud SQL, Dataproc
#     and Composer agents hold that same role on the same project, so this
#     quietly revoked them. `ignore_changes = [members]` did not prevent that —
#     it only hid the resulting drift from later plans.
#
# The grant now lives in the project-iam module, which materializes the agent
# via data.google_bigquery_default_service_account and grants it with a
# key-scoped, ADDITIVE google_kms_crypto_key_iam_member (serialized against the
# other writers of that key's IAM policy). Ordering comes from the caller: the
# platform injects depends_on = [module.project_iam] on every service module.
###############################################################################

resource "google_bigquery_dataset" "dataset" {
  project    = var.project_id
  count      = var.no_of_datasets
  dataset_id = var.dataset_name[count.index]
  location   = var.location
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
}

# Materializes the GENERIC BigQuery service agent
# (service-<num>@gcp-sa-bigquery.iam.gserviceaccount.com).
#
# Kept from v1.0.2 so upgrading does not destroy an existing resource, but note
# what it is NOT: it was added to fix the "bq-…@bigquery-encryption does not
# exist" error and cannot, because that is a DIFFERENT principal. There is no
# google_project_service_identity service value that yields the encryption
# agent; only the getServiceAccount read behind
# data.google_bigquery_default_service_account creates it. That read now lives
# in the project-iam module.
resource "google_project_service_identity" "sa" {
  provider = google-beta
  project  = var.project_id
  service  = "bigquery.googleapis.com"
}
