use axum::Router;
use std::net::SocketAddr;
use tower_http::trace;
use tower_http::{services::ServeDir, trace::TraceLayer};
use tracing::{event, Level};
use tracing_appender::rolling::{RollingFileAppender, Rotation};

#[tokio::main]
async fn main() {
    let file_appender = RollingFileAppender::builder()
        .rotation(Rotation::DAILY)
        .filename_prefix("drn-ie.log")
        .build("log") // write log files to the 'log' directory
        .expect("failed to initialize rolling file appender");

    let (file_non_blocking, _guard) = tracing_appender::non_blocking(file_appender);
    let (stdout_non_blocking, _guard) = tracing_appender::non_blocking(std::io::stdout());
    tracing_subscriber::fmt()
        .with_writer(file_non_blocking)
        .with_writer(stdout_non_blocking)
        .init();

    let app = Router::new()
        .nest_service("/", ServeDir::new("/app/public"))
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(trace::DefaultMakeSpan::new().level(Level::INFO))
                .on_response(trace::DefaultOnResponse::new().level(Level::INFO)),
        );
    let port = 8080;
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();

    event!(
        Level::INFO,
        "Application will listen at {}",
        listener.local_addr().unwrap()
    );
    axum::serve(listener, app.layer(TraceLayer::new_for_http()))
        .await
        .unwrap();
}
