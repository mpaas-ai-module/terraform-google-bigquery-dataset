variable "project_id" {
  type        = string
  description = "Project id for the resource."
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
variable "kms_key_name" {
  type        = string
  description = "The name of the kms for encrypting and decrypting the dataset."
}


