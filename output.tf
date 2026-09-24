output "dataset_ids" {
  value = google_bigquery_dataset.dataset[*].id
}

output "dataset_names" {
  value = google_bigquery_dataset.dataset[*].dataset_id
}

output "dataset_self_links" {
  value = google_bigquery_dataset.dataset[*].self_link
}