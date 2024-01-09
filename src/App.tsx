import * as d3 from "d3";
import { invoke } from "@tauri-apps/api";
import { listen } from "@tauri-apps/api/event";
import {
  isRegistered,
  register,
  unregister,
} from "@tauri-apps/api/globalShortcut";
import { sendNotification } from "@tauri-apps/api/notification";
import { createEffect, createSignal, onCleanup } from "solid-js";

function App() {
  let div!: HTMLDivElement;
  const [colors, setColors] = createSignal(
    Array.from({ length: 25 }, (_, i) => (i + 1) * 1000),
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
        console.log(new Date());
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
  createEffect(() => {
    const width = 700;
    const height = 600;
    const margin = { top: 20, right: 20, bottom: 25, left: 30 };
    const svg = d3
      .select(div)
      .append("svg")
      .attr("width", width)
      .attr("height", height);
    const xScale = d3
      .scaleLinear()
      .domain([0, 24])
      .range([margin.left, width - margin.right]);
    const yScale = d3
      .scaleLinear()
      .domain([1000, 25000])
      .range([height - margin.bottom, margin.top]);
    const line = d3
      .line()
      .x((_, i) => xScale(i))
      .y((d) => yScale(d));
    svg
      .append("g")
      .attr("transform", `translate(${margin.left}, 0)`)
      .call(
        d3
          .axisLeft(yScale)
          .ticks(18)
          .tickFormat((d) => `${d / 1000}k`),
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
          .ticks(12)
          .tickFormat((d) => {
            if (d === 0) return "12am";
            if (d < 12) return `${Number(d)}am`;
            if (d === 12) return "12pm";
            return `${d - 12}pm`;
          }),
      )
      .selectAll("line")
      .attr("stroke", "lightgray")
      .attr("stroke-opacity", 0.7);
    svg
      .selectAll(".hline")
      .data(d3.range(1000, 26000, 1000))
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
      .data(d3.range(1, 25, 1))
      .enter()
      .append("line")
      .attr("class", "vline")
      .attr("x1", (d) => xScale(d))
      .attr("x2", (d) => xScale(d))
      .attr("y1", margin.top)
      .attr("y2", height - margin.bottom)
      .attr("stroke", "lightgray")
      .attr("stroke-opacity", 0.7);
    svg
      .append("g")
      .attr("class", "data-group")
      // eslint-disable-next-line solid/reactivity
      .call((group) => {
        group
          .append("path")
          .datum(colors())
          .attr("fill", "none")
          .attr("stroke", "dodgerblue")
          .attr("stroke-width", 2)
          .attr("d", line);
      });
  });
  onCleanup(() => {
    unlisten.then((unlisten) => unlisten())!;
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
      <div
        class="ml-10 w-fit rounded bg-gray-600 shadow shadow-black"
        ref={div}
      />
    </div>
  );
}

export default App;
