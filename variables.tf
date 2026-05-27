# variables.tf
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo in owner/repo format (e.g. roynx98/ur-shortener-tf)"
  default     = "roynx98/url-shortener-iac"
}

variable "github_deploy_repo" {
  type        = string
  description = "GitHub repo that deploys lambda zips, in owner/repo format"
  default     = "roynx98/url-shortener-hello-lambda"
}