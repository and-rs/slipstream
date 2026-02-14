# loop through all the models and fetch their ARNs
data "aws_bedrock_foundation_model" "selected" {
  for_each = toset(var.bedrock_model_ids)
  model_id = each.value
}

resource "aws_iam_policy" "slipstream_bedrock" {
  name = "SlipstreamBedrockAccess"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        # create list of model ARNs automatically from data
        Resource = [for m in data.aws_bedrock_foundation_model.selected : m.model_arn]
      }
    ]
  })
}
