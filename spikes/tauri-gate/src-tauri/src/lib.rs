use std::time::{SystemTime, UNIX_EPOCH};

pub fn now_ns() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_nanos()
}

/// Spike instrumentation: absolute epoch marks on stderr. A launcher script
/// records its own t0 before exec and subtracts.
pub fn mark(label: &str, ns: u128) {
    eprintln!("PERF {} {}", label, ns);
}

/// Spike instrumentation: webview-side marks and facts, onto the process's
/// own stderr, where the launcher script can read them.
#[tauri::command]
fn mark_js(name: String, epoch_ms: f64) {
    mark(&name, (epoch_ms * 1_000_000.0) as u128);
}

#[tauri::command]
fn diag(msg: String) {
    eprintln!("DIAG {}", msg);
}

/// Spike instrumentation: `GATE_AUTODRIVE=<ms>` makes the screen hold the
/// button for <ms> by itself, so memory during metering can be sampled
/// without a human finger on the trackpad.
#[tauri::command]
fn autodrive_ms() -> u64 {
    std::env::var("GATE_AUTODRIVE")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(0)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            mark("setup", now_ns());
            if let Some(w) = tauri::Manager::get_webview_window(app, "main") {
                // spike instrumentation: keep the window unoccluded, otherwise
                // WKWebView suspends requestAnimationFrame and the meter stops.
                // `set_always_on_top` is desktop-only — it does not exist in the
                // Android build of tauri, so this must be cfg-gated or the whole
                // crate fails to compile for aarch64-linux-android.
                #[cfg(desktop)]
                if std::env::var("GATE_FRONT").is_ok() {
                    let _ = w.set_always_on_top(true);
                    let _ = w.set_focus();
                }
                if let (Ok(p), Ok(s), Ok(f)) =
                    (w.outer_position(), w.outer_size(), w.scale_factor())
                {
                    // logical rect, for `screencapture -R`
                    eprintln!(
                        "DIAG rect {} {} {} {}",
                        (p.x as f64 / f) as i32,
                        (p.y as f64 / f) as i32,
                        (s.width as f64 / f) as i32,
                        (s.height as f64 / f) as i32
                    );
                }
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![mark_js, diag, autodrive_ms])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
