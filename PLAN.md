This document serves as the technical blueprint for **Slipstream**, a high-performance semantic LLM router.

# Slipstream: LLMOps Architecture & Implementation Plan

## 1. Core Objective

Minimize inference costs and optimize developer experience by dynamically routing LLM requests between **DeepSeek-V3.2** (Efficiency/Weak) and **Claude Opus 4.6** (Reasoning/Strong) based on real-time prompt complexity analysis.

## 2. Technical Stack

- **Infrastructure:** AWS Bedrock (Serverless Inference), Terraform (IaC).
- **Runtime:** Rust (Axum + Tokio) for high-concurrency, low-latency proxying.
- **Environment:** Nix (Hermetic builds), Just (Task orchestration).
- **Security:** AWS SigV4 via IAM roles (Least Privilege), Bedrock Guardrails.
- **Observability:** OpenTelemetry (OTel) for cost and latency attribution.

## 3. Operational Logic (The "Smart" Loop)

1. **Ingress:** Slipstream listens on `:3000` for OpenAI-compatible JSON payloads.
2. **Preprocessing:**
   - **Prefix Extraction:** Extract the first 1,000 tokens of the prompt.
   - **Speculative Bypass:** If prompt < 50 tokens, default to Weak model (bypass classifier).
3. **Classification:**
   - Asynchronous call to DeepSeek-Lite or Nano-model.
   - Prompt: `Complexity [0: Routine, 1: Complex]. Input: {prefix}`.
   - **Strict Timeout:** 500ms limit on classification to prevent UX lag.
4. **Dispatch:**
   - **0 (Routine):** Route to DeepSeek-V3.2 via Bedrock.
   - **1 (Complex):** Route to Claude Opus 4.6 via Bedrock.
5. **Egress:** Stream Server-Sent Events (SSE) back to TUI/CLI without buffering.

## 4. Incremental Build Phases

### Phase 1: The "Wire" (Current)

- Implement `axum` server with `/v1/chat/completions` endpoint.
- Hard-route all traffic to DeepSeek-V3.2 via AWS SDK.
- **Success Metric:** TUI receives a streamed response from Bedrock through Slipstream.

### Phase 2: The "Brain"

- Implement the Classification logic.
- Handle model selection logic (Weak vs. Strong).
- Implement **Request Hedging**: Failover to Weak model if Strong model returns 429/500.

### Phase 3: The "Eyes"

- Integrate `tracing-opentelemetry`.
- Calculate and export metrics: `latency_ms`, `tokens_consumed`, `cost_usd`, and `routing_decision`.
- Build a `Just` recipe to visualize cost savings.

## 5. Stress Test Constraints (To Be Monitored)

- **Latency Tax:** Routing decision + classification must remain < 15% of total request time.
- **Memory Footprint:** Use Rust's zero-copy parsing (`serde`) to keep container size < 50MB.
- **Signature Integrity:** Ensure SigV4 signing remains valid across region-specific Bedrock endpoints.

---

**Status:** Infrastructure Verified (Terraform Plan ✅). Environment Ready (Nix ✅). **Next Action:** Implement Phase 1 (The Wire) in `src/main.rs`.
