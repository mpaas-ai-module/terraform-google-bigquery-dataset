variable "project_id" {
  type        = string
  description = "Project id for the resource is temptest-dev-419685"
}
variable "dataset_name" {
  type        = list(string)
  description = "The dataset name."
}
variable "no_of_datasets" {
  type        = number
  description = "The dataset name."
}
variable "location" {
  type        = string
  description = "Location of dataset"
}