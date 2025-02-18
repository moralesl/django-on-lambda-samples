# Django on AWS Lambda

This project demonstrates how to deploy a Django application on AWS Lambda using Terraform.
It includes two different approaches, packaged as Zip file and packaged as Docker container.

## Prerequisites
- Python 3.13
- AWS Account
- Required AWS services setup (Lambda, API Gateway, etc.)

## Setup for both approaches
1. Clone the repository
2. Create virtual environment: `python -m venv venv`
3. Activate the environment: `source /venv/bin/activate`
3. Install for both projects dependencies: `pip install -r requirements.txt`
4. Copy `.env.example` to `.env` and fill in your values

## Django on Lambda
This approach shows how to run a Django application in Lambda, by leveraging [Mangun](https://mangum.fastapiexpert.com/) as an adapter for running ASGI applications on Lambda.

### Local Development
To develop and run the application locally, use `docker-compose up` to start the database container. Use `docker-compose up db --detach` if you want to run it detached.

Then you can initialize the application by running `python manage.py migrate` and `python manage.py createsuperuser`.

Afterwards you can start the web server with `python manage.py runserver` and open up the website on `http://localhost:8000/admin` to connect to the admin panel.


### Deployment
For Zip, we have to build the Zip package first by running `./redeploy.zip`. This can run terraform apply for redeployments.

Change in to the terraform folders, by using `cd terraform` and initialize the terraform project with `terraform init`.
Replace the `terraform.tfvars` values with your settings and then you can deploy by running `terraform apply`.

For initialization of the database a dedicated `setup_db` Lambda function will be deployed, which you can simply trigger.
Afterwards you can open the website in the browser, e.g. `https://abcdefgh.execute-api.eu-central-1.amazonaws.com/admin/`


## Django on Lambda via Docker
This approach shows how to run a Django application in Lambda, by leveraging [AWS Lambda Web Adapter](https://github.com/awslabs/aws-lambda-web-adapter).

![AWS Lambda Web Adapter overview](AWS%20Lambda%20Web%20Adapter.png)


### Local Development
For the first time initialization (running migrate and creation of super user), uncomment in the [Dockerfile](./django-on-lambda-docker/Dockerfile#L17-21) and comment after the first startup.

To develop and run the application locally, use `docker-compose up` to start the application and database container.

Afterwards you can open up the website on `http://localhost:8000/admin` to connect to the admin panel.


### Deployment
Change in to the terraform folders, by using `cd terraform` and initialize the terraform project with `terraform init`.
Replace the `terraform.tfvars` values with your settings and then you can deploy by running `terraform apply`.

For initialization of the database see the initialization above. For updating the image, you can execute the `update_ecr.sh`.

Afterwards you can open the website in the browser, e.g. `https://abcdefgh.execute-api.eu-central-1.amazonaws.com/admin/`


## Benchmarking
Based on the different approaches, you can find a benchmark for [cold start](https://lambda-power-tuning.show/#gAAAAQACAAQABsALABQAKA==;NUZERRKj/USDqLREuH6URFiRiER7nIdEqJaJRFrMh0Q=;w5mBNlKuhDa0VoQ2kpKRNm9xqjbk0xo3lg6CN7RWBDg=;gAAAAQACAAQABsALABQAKA==;f0ZIRbRA/kRmdrdEx2uURGb+kkSHpoJE46WJRCkshEQ=;HZGENlKuhDZ3iIc2ZQeSNntXszYk0Rg30Z6GN6UyAzg=;ZIP;Container) and [warm start](https://lambda-power-tuning.show/#gAAAAQACAAQABsALABQAKA==;NQWwRDdwUUTiE7xDOZtgQwwpNkO6KS9DDAkwQ0ihJUM=;8b4gNktvPzZQCiw2DERONuOHejaM7es2Ou5JN6aFvjc=;gAAAAQACAAQABsALABQAKA==;hdexRJQxNUSzVrlDKfxnQ8PONkNyLy5DLsQoQzLhI0M=;B3UiNsqmJTYywik2kqdUNlvmezZhluo20vFBN4g9vDc=;ZIP;container) performance comparison.

Additionally, if we compare [Lambda Snapstart for Python](https://aws.amazon.com/blogs/aws/aws-lambda-snapstart-for-python-and-net-functions-is-now-generally-available/) (requires ZIP) for [cold start](https://lambda-power-tuning.show/#gAAAAQACAAQABsALABQAKA==;NUZERRKj/USDqLREuH6URFiRiER7nIdEqJaJRFrMh0Q=;w5mBNlKuhDa0VoQ2kpKRNm9xqjbk0xo3lg6CN7RWBDg=;gAAAAQACAAQABsALABQAKA==;ZHtyRY+WFkV1y9lEPy29RLQ4uETyqqxEXkK3RNUI0kQ=;HkvvNvGM/zYBIRo3qjVuNxqvszfo9xU4fA+AOKHADDk=;ZIP;ZIP%20with%20Snapstart) and [warm start](https://lambda-power-tuning.show/#gAAAAQACAAQABsALABQAKA==;NQWwRDdwUUTiE7xDOZtgQwwpNkO6KS9DDAkwQ0ihJUM=;8b4gNktvPzZQCiw2DERONuOHejaM7es2Ou5JN6aFvjc=;gAAAAQACAAQABsALABQAKA==;pltaQ+xRw0L4UzBCdgX2QWgRDUIGgfNBn2H5QbNW/kE=;huDHNPS1tDRSSKQ0b6XpNJUjRTXROKY1ZQcSNqCXljY=;ZIP;ZIP%20with%20Snapstart) performance comparison.
