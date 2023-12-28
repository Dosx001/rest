import { invoke } from "@tauri-apps/api";
import {
  isRegistered,
  register,
  unregister,
} from "@tauri-apps/api/globalShortcut";
import { sendNotification } from "@tauri-apps/api/notification";
import { createSignal, onMount } from "solid-js";

function App() {
  const [brightness, setBrightness] = createSignal(1);
  const updateBrightness = (value: string) => {
    invoke("redshift", {
      color: "5900",
      brightness: value,
    }).catch(console.error);
  };
  const createHotkey = (hotkey: string, action: () => void) => {
    isRegistered(hotkey)
      .then((reg) => {
        if (reg) {
          unregister(hotkey)!;
        }
      })
      .catch(console.error)
      .finally(() => {
        register(hotkey, () => {
          action();
          sendNotification({
            title: "Rest",
            body: `Brightness set to ${Math.trunc(brightness() * 100)}%`,
          });
        })!;
      });
  };
  onMount(() => {
    createHotkey("Alt+PageUp", () => {
      setBrightness(brightness() + 0.05);
      updateBrightness(brightness().toString());
      console.log(brightness());
    });
    createHotkey("Alt+PageDown", () => {
      setBrightness(brightness() - 0.05);
      updateBrightness(brightness().toString());
      console.log(brightness());
    });
  });
  return (
    <div>
      <input
        type="number"
        min="0"
        max="1"
        step="0.01"
        value={brightness()}
        onChange={(e) => {
          setBrightness(Number(e.currentTarget.value));
          updateBrightness(e.currentTarget.value);
        }}
      />
      <input
        type="range"
        min="0"
        max="1"
        step="0.01"
        value={brightness()}
        onInput={(e) => {
          setBrightness(Number(e.currentTarget.value));
          updateBrightness(e.currentTarget.value);
        }}
      />
    </div>
  );
}

export default App;
