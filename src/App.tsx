import * as d3 from "d3";
import { invoke } from "@tauri-apps/api";
import { listen } from "@tauri-apps/api/event";
import {
  isRegistered,
  register,
  unregister,
} from "@tauri-apps/api/globalShortcut";
import { sendNotification } from "@tauri-apps/api/notification";
import { Index, createSignal, onCleanup, onMount } from "solid-js";

function App() {
  let div!: HTMLDivElement;
  const [colors, setColors] = createSignal(
    Array.from({ length: 24 }, (_, i) => (i + 1) * 1000),
  );
  const [color, setColor] = createSignal(5900);
  const [brightness, setBrightness] = createSignal(100);
  const updateRedshift = () => {
    invoke("redshift", {
      color: color().toString(),
      brightness: `${brightness() / 100}`,
    }).catch(console.error);
  };
  // eslint-disable-next-line solid/reactivity
  const unlisten = listen("cron", (ev) => {
    switch (ev.payload) {
      case "reset":
        setBrightness(100);
        setColor(5900);
        updateRedshift();
        break;
      case "update":
        break;
    }
  })!;
  const createHotkey = (hotkey: string, type: boolean, action: () => void) => {
    isRegistered(hotkey)
      .then(async (reg) => {
        if (reg) await unregister(hotkey)!;
        // eslint-disable-next-line solid/reactivity
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
  onMount(() => {
    const width = 1000;
    const height = 700;
    const margin = { top: 25, right: 20, bottom: 30, left: 40 };
    const svg = d3
      .select(div)
      .append("svg")
      .attr("width", width)
      .attr("height", height);
    const xScale = d3
      .scaleLinear()
      .domain([1000, 25000])
      .range([margin.left, width - margin.right]);
    const yScale = d3
      .scaleLinear()
      .domain([0, 23])
      .range([height - margin.bottom, margin.top]);
    svg
      .append("g")
      .attr("transform", `translate(${margin.left}, 0)`)
      .call(
        d3
          .axisLeft(yScale)
          .ticks(25)
          .tickSize(12)
          .tickFormat((d) => {
            const n = Number(d);
            if (n === 23) return "12am";
            if (n === 11) return "12pm";
            if (n < 11) return `${Math.abs(n - 11)}pm`;
            return `${Math.abs(n - 23)}am`;
          }),
      )
      .selectAll("line")
      .attr("stroke", "lightgray")
      .attr("stroke-opacity", 0.7);
    svg
      .append("g")
      .attr("transform", `translate(0, ${height - margin.bottom})`)
      .call(
        d3
          .axisBottom(xScale)
          .ticks(18)
          .tickSize(12)
          .tickFormat((d) => `${Number(d) / 1000}k`),
      )
      .selectAll("line")
      .attr("stroke", "lightgray")
      .attr("stroke-opacity", 0.7);
    svg
      .selectAll(".hline")
      .data(d3.range(1, 25, 1))
      .enter()
      .append("line")
      .attr("class", "hline")
      .attr("x1", margin.left)
      .attr("x2", width - margin.right)
      .attr("y1", (d) => yScale(d))
      .attr("y2", (d) => yScale(d))
      .attr("stroke", "lightgray")
      .attr("stroke-opacity", 0.7);
    svg
      .selectAll(".vline")
      .data(d3.range(1000, 25500, 500))
      .enter()
      .append("line")
      .attr("class", "vline")
      .attr("x1", (d) => xScale(d))
      .attr("x2", (d) => xScale(d))
      .attr("y1", margin.top)
      .attr("y2", height - margin.bottom)
      .attr("stroke", "lightgray")
      .attr("stroke-opacity", 0.7);
  });
  onCleanup(() => {
    unlisten.then((unlisten) => unlisten())!;
  });
  return (
    <div>
      <div class="absolute ml-[43px] mt-4 w-[970px]">
        <Index each={colors()}>
          {(color, i) => (
            <input
              type="range"
              class="w-full"
              min="1000"
              max="25000"
              step="100"
              value={color()}
              title={`${color()}`}
              onChange={(e) => {
                setColors(colors().toSpliced(i, 1, Number(e.target.value)));
              }}
            />
          )}
        </Index>
      </div>
      <div
        class="m-4 w-fit rounded border border-black bg-gray-600 px-1 text-white shadow shadow-black"
        ref={div}
      />
    </div>
  );
}

export default App;
