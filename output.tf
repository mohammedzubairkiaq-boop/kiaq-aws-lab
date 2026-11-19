output "vpc_id" {
    description = "the id of the vpc"
    value = aws_vpc.main.id
}
output "public_subnet_id" {
    description = "the id of the public"
    value = aws_subnet.public.id
}
output "ec2_public_ip" {
    description = "the ip of the public"
    value = aws_instance.web.public_ip
}
output "s3_bucket_name" {
    description = "the name of the bucket"
    value = aws_s3_bucket.lab-bucket.id
}
