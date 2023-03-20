use std::{collections::HashMap, sync::RwLock};

use flutter_rust_bridge::StreamSink;

lazy_static::lazy_static! {
    // pub static ref CUR_SESSION_ID: RwLock<String> = Default::default();
    // pub static ref SESSIONS: RwLock<HashMap<String, Session<FlutterHandler>>> = Default::default();
    pub static ref GLOBAL_EVENT_STREAM: RwLock<HashMap<String, StreamSink<String>>> = Default::default(); // rust to dart event channel
}
