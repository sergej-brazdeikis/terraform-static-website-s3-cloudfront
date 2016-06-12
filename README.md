
## Terraform template to provision website on AWS S3 with Cloudfront and Route53

### Prerequisites

* Installed [Terraform](https://www.terraform.io)
* AWS Account. This account needs to have enough permissions to setup the infrastructure
  * AWS Access Key ID
  * AWS Secret Access Key

### Setup

* `cp secret.tfvars_template secret.tfvars`. Edit `secret.tfvars`, to put your AWS keys there.
* `cp website.tfvars_template website.tfvars`. Edit `website.tfvars`, put your website domain there
* Provision
```
terraform apply -var-file website.tfvars  -var-file secret.tfvars
```

It also creates locally state file. Read more about it [here](https://www.terraform.io/docs/state/)

### Other

* [Serverless blog costs on AWS S3](http://perfect-blog.jevsejev.io/2016/05/17/aws-serverless-blog-costs/)

### Terms

[MIT License](https://tldrlegal.com/license/mit-license)
