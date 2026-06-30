provider "aws" {
    region = "us-east-1"
}

# S3 Bucket
resource "aws_s3_bucket" "website" {
  bucket = "nextjs-portfolio-bucket-ks"
  
  tags = {
    Name = "Portfolio Website"
    Environment = "Production"
  }
}

# S3 Ownership Control
resource "aws_s3_bucket_ownership_controls" "website_ownership_controls" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block public access
  resource "aws_s3_bucket_public_access_block" "website_bucket_public_access_block" {
    bucket = aws_s3_bucket.website.id

    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
  }

  # S3 Bucket ACL
resource "aws_s3_bucket_acl" "website_bucket_acl" {

  depends_on = [
    aws_s3_bucket_ownership_controls.website,
    aws_s3_bucket_pubnlic_access_block.website_bucket_public_access_block
  ]

  bucket = aws_s3_bucket.website.id
  acl = "public-read"
}

# S3 Website Configuration
resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.website.id

  index_document { 
    suffix ="index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "$(aws_s3_bucket.website.arn)/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.website_configuration.website_endpoint
    origin_id   = "S3-Website"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  enabled             = true
  default_root_object = "index.html"
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Website"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = {
    Name = "Portfolio CloudFront"
    Environment = "Production"
  }
}