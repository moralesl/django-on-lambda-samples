FROM public.ecr.aws/lambda/python:3.12

# Switch to root to install packages
USER root

# Install PostgreSQL and development tools
RUN dnf install -y \
        postgresql-devel \
        postgresql-libs \
        gcc \
        make \
    && dnf clean all \
    && rm -rf /var/cache/dnf/*

# Copy requirements first for better caching
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install AWS Lambda Runtime Interface Client
RUN pip install --no-cache-dir awslambdaric

# Copy your application
COPY . ${LAMBDA_TASK_ROOT}

# Switch back to non-root user
USER nobody

CMD [ "handler.lambda_handler" ]
