data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ---------------------------------------------------------------------------
# Push to main (terraform apply)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "github_main_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

data "aws_iam_policy_document" "github_main_write" {
  statement {
    sid    = "S3StateWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::ur-shortener-tf-state",
      "arn:aws:s3:::ur-shortener-tf-state/terraform.tfstate",
    ]
  }

  statement {
    sid    = "S3LambdaZips"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:CreateBucket",
      "s3:DeleteBucket",
    ]
    resources = [
      aws_s3_bucket.lambda_zips.arn,
      "${aws_s3_bucket.lambda_zips.arn}/*",
    ]
  }

  statement {
    sid    = "DynamoDBWrite"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTables",
      "dynamodb:ListTagsOfResource",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:UpdateTable",
      "dynamodb:UpdateTimeToLive",
    ]
    resources = [
      aws_dynamodb_table.url_shortener.arn,
    ]
  }

  statement {
    sid    = "IAMWrite"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:PassRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListOpenIDConnectProviders",
      "iam:GetOpenIDConnectProvider",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "github_main" {
  name               = "github-main-role"
  assume_role_policy = data.aws_iam_policy_document.github_main_assume_role.json
}

resource "aws_iam_role_policy" "github_main_write" {
  name   = "github-main-write"
  role   = aws_iam_role.github_main.id
  policy = data.aws_iam_policy_document.github_main_write.json
}

# ---------------------------------------------------------------------------
# Pull request (terraform plan)
# ---------------------------------------------------------------------------

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
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:GetRolePolicy"
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
