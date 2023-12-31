use serde::{Deserialize, Serialize};
use std::io::Read;

#[derive(Debug, Deserialize, Serialize)]
enum MessageType {
    BrightnessUp,
    BrightnessDown,
    Temperature,
}

#[derive(Debug, Serialize, Deserialize)]
enum MessageContent {
    Text(String),
    Number(i32),
}

#[derive(Debug, Serialize, Deserialize)]
struct Message {
    message_type: MessageType,
    content: MessageContent,
}

struct Redshift {
    pub color: i32,
    brightness: f32,
}

impl Redshift {
    fn update(&self) {
        std::process::Command::new("redshift")
            .args([
                "-P",
                "-O",
                &self.color.to_string(),
                "-b",
                format!("{}", self.brightness / 100.0).as_str(),
            ])
            .spawn()
            .expect("failed to execute process");
    }
    fn inc_brightness(&mut self) {
        // self.brightness += if self.brightness == 100.0 { 0 } else { 5 };
        self.brightness += 5.0;
        println!("{}", self.brightness);
    }
    fn dec_brightness(&mut self) {
        // self.brightness -= if self.brightness == 0.0 { 0 } else { 5 };
        self.brightness -= 5.0;
        println!("{}", self.brightness);
    }
}

fn main() {
    let mut buffer = [0; 512];
    let mut redshift = Redshift {
        color: 5300,
        brightness: 100.0,
    };
    loop {
        let bytes_read = std::io::stdin().read(&mut buffer);
        let data = serde_json::from_slice::<Message>(&buffer[0..bytes_read.unwrap()]).unwrap();
        match data.message_type {
            MessageType::BrightnessUp => {
                redshift.inc_brightness();
            }
            MessageType::BrightnessDown => {
                redshift.dec_brightness();
            }
            MessageType::Temperature => {
                //9 1000K and 25000K.
                println!("Temperature: {}", redshift.color);
            }
        }
        redshift.update();
    }
}
