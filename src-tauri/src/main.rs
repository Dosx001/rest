// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::{CustomMenuItem, Manager, SystemTrayEvent, SystemTrayMenuItem};

#[tauri::command]
fn redshift(color: &str, brightness: &str) {
    std::process::Command::new("redshift")
        .args(["-P", "-O", color, "-b", brightness])
        .spawn()
        .expect("failed to execute process");
}

#[tauri::command]
fn message() {
    let mut stream = std::net::TcpStream::connect("127.0.0.1:4444").unwrap();
    std::io::Write::write_all(
        &mut stream,
        r#"{'message_type': 'Text', 'content': {'Text': 'Hello from the client!'}}"#.as_bytes(),
    )
    .expect("failed to write to stream");
    let mut buffer = [0; 512];
    let x = std::io::Read::read(&mut stream, &mut buffer).unwrap();
    let data = std::str::from_utf8(&buffer[0..x]).unwrap();
    println!("{:?}", data);
}

#[tauri::command]
fn inc_brightness() {
    let mut stream = std::net::TcpStream::connect("127.0.0.1:4444").unwrap();
    std::io::Write::write_all(
        &mut stream,
        r#"{'message_type': 'BrightnessUp'}"#.as_bytes(),
    )
    .expect("failed to write to stream");
}

#[tauri::command]
fn dec_brightness() {
    let mut stream = std::net::TcpStream::connect("127.0.0.1:4444").unwrap();
    std::io::Write::write_all(
        &mut stream,
        r#"{'message_type': 'BrightnessDown'}"#.as_bytes(),
    )
    .expect("failed to write to stream");
}

fn main() {
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
        .invoke_handler(tauri::generate_handler![
            message,
            redshift,
            inc_brightness,
            dec_brightness
        ])
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
