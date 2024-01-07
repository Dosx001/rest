import { invoke } from "@tauri-apps/api";
import { listen } from "@tauri-apps/api/event";
import {
  isRegistered,
  register,
  unregister,
} from "@tauri-apps/api/globalShortcut";
import { sendNotification } from "@tauri-apps/api/notification";
import { createSignal } from "solid-js";

function App() {
  const [brightness, setBrightness] = createSignal(100);
  const updateRedshift = (value: number) => {
    invoke("redshift", {
      color: "5900",
      brightness: `${value / 100}`,
    }).catch(console.error);
  };
  listen("cron", (ev) => {
    switch (ev.payload) {
      case "reset":
        setBrightness(100);
        break;
      case "update":
        console.log("update");
        break;
    }
  })!;
  const createHotkey = (hotkey: string, action: () => void) => {
    isRegistered(hotkey)
      .then((reg) => {
        if (reg) unregister(hotkey)!;
      })
      .catch(console.error)
      .finally(() => {
        register(hotkey, () => {
          action();
          sendNotification({
            title: "Rest",
            body: `Brightness set to ${brightness()}%`,
          });
        })!;
      });
  };
  createHotkey("Alt+PageUp", () => {
    if (brightness() === 100) return;
    setBrightness(brightness() + 5);
    updateRedshift(brightness());
  });
  createHotkey("Alt+PageDown", () => {
    if (brightness() === 10) return;
    setBrightness(brightness() - 5);
    updateRedshift(brightness());
  });
  return (
    <div>
      <input
        type="number"
        min="10"
        max="100"
        step="5"
        value={brightness()}
        onChange={(e) => {
          setBrightness(Number(e.currentTarget.value));
          updateRedshift(Number(e.currentTarget.value));
        }}
      />
      <input
        type="range"
        min="10"
        max="100"
        step="5"
        value={brightness()}
        onInput={(e) => {
          setBrightness(Number(e.currentTarget.value));
          updateRedshift(Number(e.currentTarget.value));
        }}
      />
    </div>
  );
}

export default App;
