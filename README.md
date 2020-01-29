# directus-terraform

<img src="https://raw.githubusercontent.com/sightsoundtheatres/directus-terraform/master/assets/directus.png" height="60" alt="Directus Badge"> <img src="https://raw.githubusercontent.com/sightsoundtheatres/directus-terraform/master/assets/terraform.svg?sanitize=true" height="60" alt="Terraform Badge">

This repository contains the Terraform modules used by [Sight & Sound Theatres](https://sight-sound.com) to deploy Directus 7 into AWS ECS (Fargate), RDS (Aurora), S3, CloudFront, and Route 53. These modules are configured to deploy into two regions, us-east-1 and us-west-2 by default. More regions may be easily added by modifying `main.tf`.

##### Please note we no longer use Directus at Sight & Sound, which is why this repository is archived, and support will not be provided. You are free to fork this repository and make your own changes, however.

We cannot promise support with these modules, because they are built specifically with our environment in mind, and your environment may differ. However, if you do need help, an issue is the easiest path to getting help. Pull requests are welcome, but may not be accepted in many cases.

## Deployment

You must have a pre-configured AWS account and Route 53 zone to use these modules. Create a `terraform.tfvars` file in the root directory with the necessary variables, for example:

```
cidr   = "10.0.0.0/16"
prefix = "CMS"

r53_zone_id       = "WW473HYT2ABY21"
r53_app_subdomain = "directus"
r53_api_subdomain = "directus-api"
r53_cdn_subdomain = "cdn"

api_docker_image = "directus/api:2.0.14" 

db_name     = "directus"
db_username = "user"
db_password = "password"

cdn_cors_origins = [
  "https://example.com",
  "https://*.example.com"
]
```

When running `terraform init` you must specify information about the S3 bucket to store state in, or you may modify `main.tf` to include this information.

## Docker

We use the following Dockerfile to set up S3 integration into Directus. If you wish to use it, you must build and push it to a repository and change the `api_docker_image` variable in the `terraform.tfvars` file. Substitute `2.0.15` with the version of the Directus parent Docker image you'd like to use.

```
FROM directus/api:2.0.15

WORKDIR /var/www/html

RUN apk --no-cache add wget composer git php7-xmlwriter php7-tokenizer php7-simplexml
RUN composer require league/flysystem-aws-s3-v3
```

## CDN Module

Currently, the CloudFront and S3 setup leaves some work to be desired, as it does not allow dynamic specification of regions. Until Terraform adds for-loops, we cannot easily do this, so I am waiting to refactor this until then.
