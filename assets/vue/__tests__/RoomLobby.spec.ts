import { describe, it, expect } from "vitest"
import { slugify } from "../pages/RoomLobby.vue"

describe("slugify", () => {
  it("returns null for empty string", () => {
    expect(slugify("")).toBeNull()
  })

  it("returns null for whitespace-only string", () => {
    expect(slugify("   ")).toBeNull()
  })

  it("lowercases the text", () => {
    expect(slugify("Hello")).toBe("hello")
  })

  it("replaces spaces with hyphens", () => {
    expect(slugify("hello world")).toBe("hello-world")
  })

  it("collapses multiple spaces into a single hyphen", () => {
    expect(slugify("hello   world")).toBe("hello-world")
  })

  it("removes special characters", () => {
    expect(slugify("hello! world?")).toBe("hello-world")
  })

  it("normalizes accented characters", () => {
    expect(slugify("Café Élite")).toBe("cafe-elite")
  })

  it("handles mixed content", () => {
    expect(slugify("My Room #1")).toBe("my-room-1")
  })
})
