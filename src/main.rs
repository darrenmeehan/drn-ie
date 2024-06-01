use axum::{routing::get, Router};
use tower_http::trace::{self, TraceLayer};
use tracing::{event, span, Level};
use tracing_appender::rolling::{RollingFileAppender, Rotation};

#[tokio::main]
async fn main() {
    let file_appender = RollingFileAppender::builder()
        .rotation(Rotation::DAILY)
        .filename_prefix("drn-ie.logging")
        .build("log") // write log files to the 'log' directory
        .expect("failed to initialize rolling file appender");

    let (file_non_blocking, _guard) = tracing_appender::non_blocking(file_appender);
    let (stdout_non_blocking, _guard) = tracing_appender::non_blocking(std::io::stdout());
    tracing_subscriber::fmt()
        .with_writer(file_non_blocking)
        .with_writer(stdout_non_blocking)
        .init();

    let span = span!(Level::INFO, "bootstrap");
    let _guard = span.enter();

    let app = Router::new()
        .route("/", get(|| async { "Hello, world!" }))
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(trace::DefaultMakeSpan::new().level(Level::INFO))
                .on_response(trace::DefaultOnResponse::new().level(Level::INFO)),
        );
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();

    event!(Level::INFO, "Application will listen at 3000.");

    axum::serve(listener, app.into_make_service())
        .await
        .unwrap();
}
