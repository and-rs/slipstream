variable "target_region" {
  type        = string
  description = "The AWS region for Slipstream resources"
  # no default, provided by env
}

variable "bedrock_model_ids" {
  type    = list(string)
  default = [
    "anthropic.claude-opus-4-6-v1",
    "deepseek.v3.2"
  ]
}
