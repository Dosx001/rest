import { invoke } from "@tauri-apps/api";
import {
  isRegistered,
  register,
  unregister,
} from "@tauri-apps/api/globalShortcut";
import { sendNotification } from "@tauri-apps/api/notification";
import { createSignal, onMount } from "solid-js";

function App() {
  const [brightness, setBrightness] = createSignal(100);
  const updateBrightness = (value: number) => {
    invoke("redshift", {
      color: "5900",
      brightness: `${value / 100}`,
    }).catch(console.error);
  };
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
  onMount(() => {
    createHotkey("Alt+PageUp", () => {
      if (brightness() === 100) {
        return;
      }
      setBrightness(brightness() + 5);
      updateBrightness(brightness());
    });
    createHotkey("Alt+PageDown", () => {
      if (brightness() === 10) {
        return;
      }
      setBrightness(brightness() - 5);
      updateBrightness(brightness());
    });
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
          updateBrightness(Number(e.currentTarget.value));
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
          updateBrightness(Number(e.currentTarget.value));
        }}
      />
    </div>
  );
}

export default App;
