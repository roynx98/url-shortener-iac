data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_pr_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    # Sin las condicions culquier puede ruuner puede asumier el rol
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:pull_request"]
    }
  }
}

data "aws_iam_policy_document" "github_pr_read" {
  statement {
    sid    = "S3StateRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::ur-shortener-tf-state",
      "arn:aws:s3:::ur-shortener-tf-state/terraform.tfstate",
    ]
  }

  statement {
    sid    = "DynamoDBRead"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:ListTables",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource"
    ]
    resources = [
      aws_dynamodb_table.url_shortener.arn,
    ]
  }

  statement {
    sid    = "IAMRead"
    effect = "Allow"
    actions = [
      "iam:ListOpenIDConnectProviders",
      "iam:GetOpenIDConnectProvider",
      "iam:GetRole",
      "iam:ListRolePolicies"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "github_pr" {
  name               = "github-pr-role"
  assume_role_policy = data.aws_iam_policy_document.github_pr_assume_role.json
}

resource "aws_iam_role_policy" "github_pr_read" {
  name   = "github-pr-read"
  role   = aws_iam_role.github_pr.id
  policy = data.aws_iam_policy_document.github_pr_read.json
}
