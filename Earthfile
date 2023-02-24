VERSION 0.7
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ARG --required --global AWS_PROFILE
ARG --required --global SSH_KEY_NAME

plan:
  BUILD +terraform-plan
  BUILD +ansible --EXTRA_ARGS="--diff --check"

apply:
  WAIT
    BUILD +packer
  END
  BUILD +terraform-apply
  BUILD +ansible

###############
terraform-base:
  FROM +build-image
  ENV TF_VAR_ssh_key=$SSH_KEY_NAME
  COPY --dir terraform .
  WORKDIR terraform
  RUN terraform init

terraform-plan:
  FROM +terraform-base
  DO +RUN_WITH_SECRETS --cmd="terraform plan -out=tfplan"
  SAVE ARTIFACT tfplan /tfplan
  SAVE ARTIFACT tfplan AS LOCAL terraform/tfplan

terraform-apply:
  FROM +terraform-base
  COPY +terraform-plan/tfplan .
  DO +RUN_WITH_SECRETS_PUSH --cmd="terraform apply tfplan"
  SAVE ARTIFACT terraform.tfstate AS LOCAL terraform/terraform.tfstate

packer:
  FROM +build-image
  ENV PKR_VAR_ssh_key=$SSH_KEY_NAME
  COPY --dir packer ansible .
  WORKDIR packer
  RUN packer init .
  RUN packer fmt .
  DO +RUN_WITH_SECRETS --cmd="packer validate ."
  DO +RUN_WITH_SECRETS_PUSH --cmd="packer build config.pkr.hcl"

ansible:
  FROM +build-image
  ARG EXTRA_ARGS=""
  COPY --dir ansible .
  WORKDIR ansible
  DO +RUN_WITH_SECRETS_PUSH --cmd="ansible-playbook -i aws_ec2.yaml playbook.yaml --private-key ~/.ssh/$SSH_KEY_NAME $EXTRA_ARGS"

build-image:
  ARG ANSIBLE_VERSION=7.2.0
  ARG TERRAFORM_VERSION=1.3.9
  ARG PACKER_VERSION=1.8.6

  RUN apt-get -qq update && apt-get -qq install -y python3 wget unzip ssh && rm -rf /var/cache/apt/lists
  RUN wget -q -O- https://bootstrap.pypa.io/get-pip.py | python3
  RUN pip3 install ansible==$ANSIBLE_VERSION boto3 botocore
  RUN wget -q -O tf.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && unzip tf.zip && mv terraform /usr/local/bin && rm tf.zip
  RUN wget -q -O packer.zip https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && unzip packer.zip && mv packer /usr/local/bin && rm packer.zip

RUN_WITH_SECRETS_PUSH:
  COMMAND
  ARG cmd
  RUN --mount=type=secret,target=$HOME/.ssh/$SSH_KEY_NAME,id=SSH_KEY_CONTENT,mode=0400 \
    --mount=type=secret,target=$HOME/.aws/credentials,id=AWS_CREDENTIALS,mode=0400 \
    --push \
    --no-cache \
    $cmd

RUN_WITH_SECRETS:
  COMMAND
  ARG cmd
  RUN --mount=type=secret,target=$HOME/.ssh/$SSH_KEY_NAME,id=SSH_KEY_CONTENT,mode=0400 \
    --mount=type=secret,target=$HOME/.aws/credentials,id=AWS_CREDENTIALS,mode=0400 \
    --no-cache \
    $cmd
