# Slipstream

Rust-based proxy that dynamically routes LLM requests between cost-efficient and high-capability models (DeepSeek-V3.2 and Claude Opus 4.6) based on real-time prompt complexity analysis. It implements a smart routing layer on top of AWS Bedrock to optimize inference costs while maintaining performance for complex tasks.

## Core Architecture

- **Routing Logic**: Classifies prompts as routine (0) or complex (1) using a lightweight classifier, routes to appropriate model
- **Infrastructure**: AWS Bedrock for serverless inference, Terraform for IaC, deployed in us-west-2
- **Runtime**: Rust with Axum/Tokio for high-concurrency, low-latency proxying (<15% routing overhead)
- **Observability**: OpenTelemetry integration for cost attribution and performance monitoring

## Quick Start

- Remember the setup is much easier with nix, otherwise bring your own dependencies by installing what is listed on the `./flake.nix` file.

```bash
# Enter development environment
nix develop

# Configure AWS credentials.
# I recommend using login instead of configure and
# letting the flake.nix handle the default profile
aws login

# Initialize infrastructure
just tf-init
just tf-plan
just tf-apply

# Build and run
just build
just run
```

## Project Structure

- `src/main.rs` - Axum server with `/v1/chat/completions` endpoint (Phase 1: The Wire)
- `infra/` - Terraform configuration for IAM policies and AWS resources
- `flake.nix` - Nix development environment with Rust toolchain and AWS tooling
- `justfile` - Task orchestration for common operations
- `PLAN.md` - Detailed technical implementation plan with phased rollout

## Key Features

- **Smart Routing**: Real-time prompt complexity analysis with 500ms classification timeout
- **Request Hedging**: Automatic failover to weak model on strong model failures (429/500)
- **Cost Optimization**: Estimated 60-80% cost reduction by routing routine tasks to DeepSeek-V3.2
- **OpenAI Compatibility**: Accepts standard OpenAI API payloads, streams SSE responses
- **Zero-Copy Parsing**: Memory footprint <50MB through efficient Rust serialization

## Development Phases

1. **Phase 1 (Current)**: Basic routing to DeepSeek-V3.2 with streaming responses
2. **Phase 2**: Implement classification logic and model selection with failover
3. **Phase 3**: Add OpenTelemetry instrumentation for cost/latency attribution

## Configuration

Environment variables set in shellHook:

- `AWS_PROFILE=nix-dev` - IAM profile with Bedrock permissions
- `REGION=us-west-2` - Default AWS region
- `RUST_SRC_PATH` - Configured for rust-analyzer support

Terraform variables in `infra/variables.tf`:

- `bedrock_model_ids` - List of Bedrock model IDs for IAM policy generation
- `target_region` - AWS region for resource deployment

## Testing & Validation

```bash
# Check AWS authentication
just check-auth

# List available Bedrock models
just ls-models

# Run load tests
hey -m POST -H "Content-Type: application/json" -D test_payload.json http://localhost:3000/v1/chat/completions
```

## Constraints & Monitoring

- Classification latency must not exceed 500ms
- Routing overhead must remain below 15% of total request time
- Memory usage target: <50MB container size
- Signature validation across AWS regions must be maintained

## Next Steps

Implement Phase 2 classification logic using DeepSeek-Lite for prompt analysis, add request hedging for automatic failover, and integrate OpenTelemetry tracing for cost attribution metrics.
