# cli utils
ls-models:
    aws bedrock list-foundation-models --region us-east-1 --query "modelSummaries[*].modelId" --output text \
    | tr '\t' '\n' \
    | fzf --multi --header "Select models with [TAB], press [ENTER] to output"

check-auth:
    aws sts get-caller-identity

# terraform
tf-reinit:
    cd infra && terraform init -reconfigure

tf-init:
    cd infra && terraform init

tf-plan:
    cd infra && terraform plan -out=tfplan

tf-apply:
    cd infra && terraform apply tfplan

# rust
build:
    cargo build --release

run:
    cargo run

# all-in-one
setup: tf-init build
