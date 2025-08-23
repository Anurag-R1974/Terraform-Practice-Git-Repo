module "lambda_function" {
  source = "../Day-09-Terraform-Sources/terraform-aws-lambda"

  function_name  = "my-basic-lambda"
  lambda_role = "arn:aws:iam::825765403572:role/lambda-ec2"
  create_package = false
  local_existing_package = "${path.module}/lambda_function.zip"

  handler     = "lambda_function.lambda_handler"
  runtime     = "python3.9"
  memory_size = 256
  timeout     = 900
}