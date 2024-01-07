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
  const [color, setColor] = createSignal(5900);
  const [brightness, setBrightness] = createSignal(100);
  const updateRedshift = () => {
    invoke("redshift", {
      color: color().toString(),
      brightness: `${brightness() / 100}`,
    }).catch(console.error);
  };
  listen("cron", (ev) => {
    switch (ev.payload) {
      case "reset":
        setBrightness(100);
        setColor(5900);
        updateRedshift();
        break;
      case "update":
        console.log(new Date());
        break;
    }
  })!;
  const createHotkey = (hotkey: string, type: boolean, action: () => void) => {
    isRegistered(hotkey)
      .then(async (reg) => {
        if (reg) await unregister(hotkey)!;
        register(hotkey, () => {
          action();
          sendNotification({
            title: "Rest",
            body: type
              ? `Color set to ${color()}`
              : `Brightness set to ${brightness()}%`,
          });
        })!;
      })
      .catch(console.error);
  };
  createHotkey("Alt+PageUp", false, () => {
    if (brightness() === 100) return;
    setBrightness(brightness() + 5);
    updateRedshift();
  });
  createHotkey("Alt+PageDown", false, () => {
    if (brightness() === 10) return;
    setBrightness(brightness() - 5);
    updateRedshift();
  });
  createHotkey("Alt+Home", true, () => {
    if (color() === 25000) return;
    setColor(color() + 100);
    updateRedshift();
  });
  createHotkey("Alt+End", true, () => {
    if (color() === 1000) return;
    setColor(color() - 100);
    updateRedshift();
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
          updateRedshift();
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
          updateRedshift();
        }}
      />
    </div>
  );
}

export default App;
