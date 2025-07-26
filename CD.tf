resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "website_bucket" {
  bucket =  "static-site-bucket-${random_id.suffix.hex}"
  
    tags = {
    Name        = "website_bucket"
    Environment = "Dev"
  }
}



resource "aws_s3_bucket_public_access_block" "website_bucket_public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      }
   ]
  })

   depends_on = [aws_s3_bucket_public_access_block.website_bucket_public_access]

}

resource "aws_s3_bucket" "ci_cd_bucket" {
  bucket =  "ci-cd-bucket${random_id.suffix.hex}"

}

resource "aws_s3_bucket_versioning" "ci_cd_bucket_versioning" {
  bucket = aws_s3_bucket.ci_cd_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}



resource "aws_kms_key" "s3_key" {
  description             = "KMS key for CodePipeline artifact encryption"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "s3kmskey" {
  name          = "alias/myKmsKey"
  target_key_id = aws_kms_key.s3_key.key_id
}

resource "aws_iam_role_policy" "codebuild_kms_policy" {
  name = "codebuild-kms-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource =  "${aws_kms_key.s3_key.arn}"
      }
    ]
  })
}



resource "aws_codepipeline" "codepipeline" {
  name     = "my-code-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  depends_on = [
    aws_iam_role.codepipeline_role,
    aws_codebuild_project.test_build
  ]

  artifact_store {
    location = aws_s3_bucket.ci_cd_bucket.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_alias.s3kmskey.arn

      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.my_app.arn
        FullRepositoryId = "Emeka-Okafor/Updated-Vs-SWH"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.test_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployStaticSite"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
      BucketName = aws_s3_bucket.website_bucket.bucket
      Extract    = "true"
    }
  }
}
}


resource "aws_codestarconnections_connection" "my_app" {
  name          = "GitHub-Connection"
  provider_type = "GitHub"
}



data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "test-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"
    
    actions = [
      "s3:GetBucketVersioning",
      "s3:PutObject",
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.ci_cd_bucket.arn}/*"
    ]
 }


    statement {
     effect    = "Allow"
     actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.my_app.arn]
  }

     statement {
      effect = "Allow"
      actions = [
       "codebuild:BatchGetBuilds",
       "codebuild:StartBuild",
       "cloudformation:CreateStack",
       "cloudformation:UpdateStack",
       "cloudformation:DescribeStacks",
       "cloudformation:DeleteStack"
    ]
   
    resources = ["*"]
  }


     statement {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
        "kms:DescribeKey"


    ]
  
   resources = [aws_kms_key.s3_key.arn]

 }

}


resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_codebuild_project" "test_build" {
  name          =  "static-site-build"
  description   = "Build static site"
  build_timeout = 5
  service_role  =  aws_iam_role.codebuild_role.arn  

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.ci_cd_bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ARTIFACT_BUCKET_NAME"
      value =  aws_s3_bucket.ci_cd_bucket.bucket
    }

  
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.ci_cd_bucket.id}/build-log"
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec.yml"
 }

}

resource "aws_cloudwatch_log_group" "build_log_group" {
  name = "log-group"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "build_log_stream" {
  name           = "log-stream"
  log_group_name = aws_cloudwatch_log_group.build_log_group.name

  depends_on = [
  aws_cloudwatch_log_group.build_log_group,
  
]

}

output "website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}



