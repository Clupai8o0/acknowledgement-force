use std::{
    fs::OpenOptions,
    io::Write,
    path::PathBuf,
    time::{SystemTime, UNIX_EPOCH},
};
use tauri::{AppHandle, Manager};

fn ensure_autostart(app: &AppHandle) -> Result<(), String> {
    let app_data = std::env::var("APPDATA").map_err(|err| err.to_string())?;
    let startup_dir = PathBuf::from(app_data)
        .join("Microsoft")
        .join("Windows")
        .join("Start Menu")
        .join("Programs")
        .join("Startup");
    std::fs::create_dir_all(&startup_dir).map_err(|err| err.to_string())?;

    let exe_path = tauri::process::current_binary(&app.env()).map_err(|err| err.to_string())?;
    let script_path = startup_dir.join("AcknowledgementAppStartup.cmd");

    if script_path.exists() {
        return Ok(());
    }

    let script = format!(
        "@echo off\r\nstart \"\" \"{}\"\r\n",
        exe_path.display()
    );
    std::fs::write(&script_path, script).map_err(|err| err.to_string())?;

    Ok(())
}

#[tauri::command]
fn record_acknowledgement(app: AppHandle) -> Result<(), String> {
    let dir = app.path().app_data_dir().map_err(|err| err.to_string())?;
    std::fs::create_dir_all(&dir).map_err(|err| err.to_string())?;

    let file_path = dir.join("acknowledgements.log");
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|err| err.to_string())?;
    let line = format!("acknowledged_at_ms={}\n", now.as_millis());

    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(file_path)
        .map_err(|err| err.to_string())?;
    file.write_all(line.as_bytes())
        .map_err(|err| err.to_string())?;

    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            if let Err(err) = ensure_autostart(app.handle()) {
                eprintln!("autostart setup failed: {}", err);
            }
            Ok(())
        })
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![record_acknowledgement])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
