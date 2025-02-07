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
