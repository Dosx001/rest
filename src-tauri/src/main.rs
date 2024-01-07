// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::{CustomMenuItem, Manager, SystemTrayEvent, SystemTrayMenuItem};

#[tauri::command]
fn redshift(color: &str, brightness: &str) {
    std::process::Command::new("redshift")
        .args(["-P", "-O", color, "-b", brightness])
        .spawn()
        .expect("failed to execute process")
        .wait()
        .unwrap();
}

async fn cron_jobs(window: tauri::Window) {
    let sched = tokio_cron_scheduler::JobScheduler::new().await.unwrap();
    let winc = window.clone();
    let _ = sched
        .add(
            tokio_cron_scheduler::Job::new("@daily", move |_, _| {
                let _ = winc.emit("cron", "reset");
            })
            .unwrap(),
        )
        .await;
    let _ = sched
        .add(
            tokio_cron_scheduler::Job::new("@hourly", move |_, _| {
                let _ = window.clone().emit("cron", "update");
            })
            .unwrap(),
        )
        .await;
    let _ = sched.start().await;
}

#[tokio::main]
async fn main() {
    let mut hide = CustomMenuItem::new("hide".to_string(), "Hide");
    hide = hide.accelerator("h".to_string());
    let mut show = CustomMenuItem::new("show".to_string(), "Show");
    show = show.accelerator("s".to_string());
    let mut quit = CustomMenuItem::new("quit".to_string(), "Quit");
    quit = quit.accelerator("q".to_string());
    let tray_menu = tauri::SystemTrayMenu::new()
        .add_item(hide)
        .add_item(show)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(quit);
    let system_tray = tauri::SystemTray::new().with_menu(tray_menu);
    tauri::Builder::default()
        .setup(move |app| {
            let window = app.get_window("main").unwrap();
            tokio::spawn(cron_jobs(window));
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![redshift,])
        .system_tray(system_tray)
        .on_system_tray_event(|app, event| {
            if let SystemTrayEvent::MenuItemClick { id, .. } = event {
                match id.as_str() {
                    "hide" => {
                        let window = app.get_window("main").unwrap();
                        window.hide().unwrap();
                    }
                    "show" => {
                        let window = app.get_window("main").unwrap();
                        window.show().unwrap();
                    }
                    "quit" => {
                        std::process::exit(0);
                    }
                    _ => {}
                }
            }
        })
        .on_window_event(|event| {
            if let tauri::WindowEvent::CloseRequested { api, .. } = event.event() {
                event.window().hide().unwrap();
                api.prevent_close();
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
