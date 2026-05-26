import { describe, it, expect } from "vitest"
import { avatarInitials, avatarColor } from "../pages/GuestOnboarding.vue"

describe("avatarInitials", () => {
  it("returns ? for empty string", () => {
    expect(avatarInitials("")).toBe("?")
  })

  it("returns ? for whitespace-only string", () => {
    expect(avatarInitials("   ")).toBe("?")
  })

  it("returns single uppercase initial for one-word name", () => {
    expect(avatarInitials("alice")).toBe("A")
    expect(avatarInitials("Bob")).toBe("B")
  })

  it("returns two initials for multi-word name", () => {
    expect(avatarInitials("Alice Smith")).toBe("AS")
    expect(avatarInitials("john doe")).toBe("JD")
  })

  it("uses first and last word for names with more than two words", () => {
    expect(avatarInitials("Mary Jane Watson")).toBe("MW")
  })
})

describe("avatarColor", () => {
  it("returns the same color for the same name", () => {
    expect(avatarColor("Alice")).toBe(avatarColor("Alice"))
  })

  it("returns a valid DaisyUI color token", () => {
    const validColors = ["primary", "secondary", "accent", "info", "success", "warning", "error"]
    expect(validColors).toContain(avatarColor("Alice"))
    expect(validColors).toContain(avatarColor("Bob"))
    expect(validColors).toContain(avatarColor(""))
  })
})
