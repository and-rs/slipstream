use aws_sdk_bedrockruntime::Client as BedrockClient;
use aws_sdk_bedrockruntime::types::ResponseStream;
use axum::{
    Json, Router,
    extract::State,
    response::{Sse, sse::Event},
    routing::post,
};
use futures_util::Stream;
use serde::Deserialize;
use std::sync::Arc;

#[derive(Debug, Deserialize)]
struct ChatMessage {
    content: String,
}

#[derive(Debug, Deserialize)]
struct ChatRequest {
    messages: Vec<ChatMessage>,
}

struct AppState {
    bedrock: BedrockClient,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let bedrock = BedrockClient::new(&config);
    let state = Arc::new(AppState { bedrock });

    let app = Router::new()
        .route("/v1/chat/completions", post(chat_completions))
        .with_state(state);

    let addr = "0.0.0.0:3000";
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    tracing::info!("Slipstream listening on {}", addr);
    axum::serve(listener, app).await.unwrap();
}

async fn chat_completions(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<ChatRequest>,
) -> Result<Sse<impl Stream<Item = Result<Event, Infallible>>>, axum::http::StatusCode> {
    let model_id = "deepseek.v3.2";
    let prompt = payload.messages.last().map(|m| &m.content).unwrap();

    let body = serde_json::json!({
        "prompt": prompt,
        "max_tokens": 4096
    });

    let response_result = state
        .bedrock
        .invoke_model_with_response_stream()
        .model_id(model_id)
        .body(aws_sdk_bedrockruntime::primitives::Blob::new(
            serde_json::to_vec(&body).unwrap(),
        ))
        .send()
        .await;

    let response = match response_result {
        Ok(res) => res,
        Err(e) => {
            tracing::error!("Bedrock Error: {:?}", e);
            // In the future, this is where we trigger Failover to the other model
            return Err(axum::http::StatusCode::TOO_MANY_REQUESTS);
        }
    };

    let stream = async_stream::stream! {
        let mut receiver = response.body;
        while let Ok(Some(event)) = receiver.recv().await {
            match event {
                ResponseStream::Chunk(chunk) => {
                    if let Some(bytes) = chunk.bytes() {
                        let text = String::from_utf8_lossy(bytes.as_ref()).to_string();
                        // Note: Different models return different JSON schemas
                        yield Ok(Event::default().data(text));
                    }
                }
                _ => yield Ok(Event::default().data("[END]")),
            }
        }
    };

    Ok(Sse::new(stream))
}

use std::convert::Infallible;
