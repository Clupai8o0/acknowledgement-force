// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    // First statement in the process we control: used as the "Rust main" mark
    // for the cold-start measurement. Everything before this is dyld + runtime.
    tauri_gate_lib::mark("main", tauri_gate_lib::now_ns());
    tauri_gate_lib::run()
}
