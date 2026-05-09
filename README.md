# AWS Terraform Lab 1

Готовий каркас лабораторної роботи під вимоги:
- усі AWS ресурси описані Terraform
- неймінг через `cloudposse/label/null` (`terraform-null-label`)
- без хардкоду ARN між ресурсами
- використано remote state (`backend s3`) і `terraform_remote_state`
- DynamoDB таблиці створюються через custom module
- backend bucket + lock table створюються через AWS CLI

## Архітектура

- **DynamoDB**: `authors`, `courses`
- **Lambda**: `get-all-authors`, `get-all-courses`, `get-course`, `save-course`, `update-course`, `delete-course`
- **API Gateway**:
  - `GET /authors`
  - `GET /courses`
  - `GET /courses/{id}`
  - `POST /courses`
  - `PUT /courses/{id}`
  - `DELETE /courses/{id}`
- **S3**: статичний frontend
- **CloudFront**: доставка frontend

## Структура

```text
aws-terraform-lab1/
├── frontend/
│   └── index.html
├── lambdas/
│   ├── delete-course/
│   ├── get-all-authors/
│   ├── get-all-courses/
│   ├── get-course/
│   ├── save-course/
│   └── update-course/
├── modules/
│   └── dynamodb_table/
├── stacks/
│   ├── app/
│   └── data/
└── README.md
```

## 0. Передумови

1. Створи **IAM admin user**, а не працюй з `root`.
2. Налаштуй AWS CLI:

```bash
aws configure
```

3. Дізнайся `account-id`:

```bash
aws sts get-caller-identity
```

## 1. Створення backend для Terraform state (CLI)

> За умовами лаби ці ресурси треба створювати **з командного рядка**, не Terraform.

```bash
aws s3api create-bucket \
  --bucket <account-id>-terraform-tfstate \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

aws s3api put-bucket-versioning \
  --bucket <account-id>-terraform-tfstate \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --region eu-central-1 \
  --table-name terraform-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
```

## 2. backend.hcl

Створи файл `backend.hcl` окремо в `stacks/data` і `stacks/app`.

### `stacks/data/backend.hcl`

```hcl
bucket         = "<account-id>-terraform-tfstate"
key            = "lab1/data/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "terraform-tfstate-lock"
encrypt        = true
```

### `stacks/app/backend.hcl`

```hcl
bucket         = "<account-id>-terraform-tfstate"
key            = "lab1/app/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "terraform-tfstate-lock"
encrypt        = true
```

## 3. tfvars приклад

### `stacks/data/terraform.tfvars`

```hcl
aws_region = "eu-central-1"
project    = "lab1"
environment = "dev"
```

### `stacks/app/terraform.tfvars`

```hcl
aws_region   = "eu-central-1"
project      = "lab1"
environment  = "dev"
state_bucket = "<account-id>-terraform-tfstate"
```

## 4. Deploy — data stack

```bash
cd stacks/data
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan
terraform apply -auto-approve
```

## 5. Deploy — app stack

```bash
cd ../app
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan
terraform apply -auto-approve
```

## 6. Що показувати викладачу

### DynamoDB
- таблиця `authors`
- таблиця `courses`
- в кожній хоча б один запис

### Lambda
- `get-all-authors`
- `get-all-courses`
- `get-course`
- `save-course`
- `update-course`
- `delete-course`

### API Gateway
- ресурси `/authors`, `/courses`, `/courses/{id}`

### S3 + CloudFront
- бакет зі статичним сайтом
- CloudFront distribution

## 7. JSON для тестів Lambda

### get-all-authors
```json
{}
```

### get-all-courses
```json
{}
```

### get-course
```json
{
  "id": "web-component-fundamentals"
}
```

### save-course
```json
{
  "title": "Web Component Fundamentals",
  "authorId": "cory-house",
  "length": "5:10",
  "category": "HTML5"
}
```

### update-course
```json
{
  "id": "web-component-fundamentals",
  "title": "Web Component Fundamentals",
  "watchHref": "http://www.pluralsight.com/courses/web-components-shadow-dom",
  "authorId": "cory-house",
  "length": "5:03",
  "category": "HTML5"
}
```

### delete-course
```json
{
  "id": "web-component-fundamentals"
}
```

## 8. JSON для API Gateway

### POST `/courses`
```json
{
  "title": "Web Component Fundamentals",
  "authorId": "cory-house",
  "length": "5:10",
  "category": "HTML5"
}
```

### PUT `/courses/web-component-fundamentals`
```json
{
  "title": "Web Component Fundamentals",
  "watchHref": "http://www.pluralsight.com/courses/web-components-shadow-dom",
  "authorId": "cory-house",
  "length": "5:03",
  "category": "HTML5"
}
```

## 9. Коміти

Рекомендовано робити commit-и за Conventional Commits:

```bash
git init
git add .
git commit -m "feat(data): add dynamodb custom module and seed data"
git commit -m "feat(app): add lambdas iam and api gateway"
git commit -m "feat(frontend): add s3 and cloudfront hosting"
```

## 10. Важливий нюанс для захисту

У сучасній документації Terraform для S3 backend сказано, що **DynamoDB locking deprecated**, але в цій лабі його все одно треба використати, бо це є прямою вимогою завдання. Це нормально сказати викладачу.
