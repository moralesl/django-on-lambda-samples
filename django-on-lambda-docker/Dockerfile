ARG TARGETPLATFORM=linux/arm64

FROM --platform=$TARGETPLATFORM python:3.13-alpine

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt && \
      pip cache purge && \
      rm -rf /root/.cache/pip/*

COPY ./app .
RUN python manage.py collectstatic --noinput --clear

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.9.0-aarch64 /lambda-adapter /opt/extensions/lambda-adapter

## Only necessary for one time initialization work
# COPY init.sh .
# RUN chmod +x init.sh

# # Use the init script as the entrypoint
# ENTRYPOINT ["./init.sh"]

CMD ["python", "manage.py", "runserver", "0.0.0.0:8080"]
