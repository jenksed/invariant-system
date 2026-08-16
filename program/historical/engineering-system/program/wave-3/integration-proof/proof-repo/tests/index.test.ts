import { test } from "node:test";
import { placeholder } from "../src/index.ts";

test("placeholder is stable", () => {
  if (placeholder !== "wave-3-proof-repo") {
    throw new Error("placeholder changed");
  }
});
