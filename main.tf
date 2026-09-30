resource "aws_s3_bucket" "MyProjectBucket" {
  bucket = "slyy-terraf-aws-buck"

  tags = {
    Name        = "MyProjectBucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "MyProjectBucketPublicAccessBlock" {
  bucket = aws_s3_bucket.MyProjectBucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "MyProjectBucketPolicy" {
  bucket = aws_s3_bucket.MyProjectBucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = [
            "s3:GetObject",
            "s3:putObject",
            "s3:DeleteObject"
            ]
        Resource  = "${aws_s3_bucket.MyProjectBucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "MyProjectBucketWebsite" {
  bucket = aws_s3_bucket.MyProjectBucket.id

  index_document {
    suffix = "index.html"
  }

}

resource "aws_s3_bucket_ownership_controls" "MyProjectBucketOwnershipControls" {
  bucket = aws_s3_bucket.MyProjectBucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "MyProjectBucketACL" {
    depends_on = [
        aws_s3_bucket_ownership_controls.MyProjectBucketOwnershipControls,
        aws_s3_bucket_public_access_block.MyProjectBucketPublicAccessBlock
    ]
  bucket = aws_s3_bucket.MyProjectBucket.id
  acl    = "public-read"
}

resource "null_resource" "UploadIndexHtml" {
  depends_on = [
    aws_s3_bucket_website_configuration.MyProjectBucketWebsite,
    aws_s3_bucket_acl.MyProjectBucketACL
  ]

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p /tmp/s3_upload

      git clone https://github.com/cloudacademy/static-website-example /tmp/s3_upload/

      rm -rf /tmp/s3_upload/.git

      aws s3 cp /tmp/s3_upload s3://${aws_s3_bucket.MyProjectBucket.bucket}/ --recursive

      rm -rf /tmp/s3_upload

    EOT
  }
}