# terraform-google-bigquery-dataset
Creates a big query datasets

## v1.0.3 — the CMEK key grant moved out of this module

Up to and including v1.0.2 this module emitted its own project-level grant of
`roles/cloudkms.cryptoKeyEncrypterDecrypter` to the BigQuery encryption agent:

```hcl
resource "google_project_iam_binding" "network_binding3" {
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = ["serviceAccount:bq-${data.google_project…number}@bigquery-encryption…"]
}
```

That was wrong twice over:

1. **The agent may not exist.** The email was interpolated from the project
   number, but the BigQuery *encryption* agent is created lazily — only when GCP
   is asked for it (`bigquery.projects.getServiceAccount`). On a fresh project
   the first apply failed with

   ```
   Error 400: Service account bq-<num>@bigquery-encryption.iam.gserviceaccount.com
   does not exist., badRequest
   ```

   v1.0.2 added `google_project_service_identity` for `bigquery.googleapis.com`
   to try to fix this. It cannot: that yields the *generic* BigQuery service
   agent (`service-<num>@gcp-sa-bigquery…`), a different principal.

2. **`google_project_iam_binding` is authoritative.** It replaces *every* member
   of that role on the whole project — silently revoking the GCS, Cloud SQL,
   Dataproc, Composer and Artifact Registry agents that hold the same role.
   `lifecycle { ignore_changes = [members] }` did not prevent that; it only hid
   the resulting drift from later plans.

The grant now lives in **`mpaas-ai-module/project-iam/google` >= 1.0.3**, which
materializes the agent with `data.google_bigquery_default_service_account` and
grants it with a key-scoped, additive `google_kms_crypto_key_iam_member`. Set
`manage_bigquery_cmek = true` on that module. Ordering comes from the caller —
the platform injects `depends_on = [module.project_iam]` on every service module.

### Upgrading an already-provisioned project

Removing a `google_project_iam_binding` makes Terraform **delete** it, which
empties that role at project level. Before the first apply on v1.0.3, abandon the
old binding instead of deleting it:

```sh
terraform state rm 'module.<label>.google_project_iam_binding.network_binding3'
```

New projects need no such step.
