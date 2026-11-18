resource "aws_vpc" "main" {
  cidr_block          = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support  = true
  tags = {
    Name = "kiaq-lab-vpc"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "kiaq-lab-igw"
  }
}
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-2a"
  tags = {
    Name = "kiaq-lab-public-subnet"
  }
}
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2b"
  tags = {
    Name = "kiaq-lab-private-subnet"
  }
}
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
    tags = {
        Name = "kiaq-lab-public-rt"
    }
}
resource "aws_route_table_association" "public_assoc" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}
resource "aws_security_group" "ec2_sg" {
    name = "kiaq-ec2-sg"
    description = "Allow inbound traffic for SSH and HTTP"
    vpc_id = aws_vpc.main.id
    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "kiaq-ec2-sg"
    }

}
resource "aws_instance" "web" {
    ami = "ami-0ba218121447b72f3"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]
    tags = {
        Name = "kiaq-lab-ec2"
    }
}
resource "aws_s3_bucket" "lab-bucket" {
  bucket = "courese-zubair123"
  force_destroy = true
  tags = {
    Name = "kiaq-lab-bucket"
  }
} 
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for KiaQ lab S3 bucket"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for KiaQ S3 bucket"
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.lab-bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

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
    Name = "kiaq-lab-cloudfront"
  }
}
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.lab-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.lab-bucket.arn}/*"
      }
    ]
  })
}
