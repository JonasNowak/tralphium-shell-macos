import Testing
@testable import TralphiumCore

@Suite struct ThemePaletteTests {
    @Test func parsesSixDigitHex() throws {
        let c = try #require(RGBA(hex: "#FF8000"))
        #expect(c.red == 1)
        #expect(abs(c.green - 128.0 / 255) < 0.0001)
        #expect(c.blue == 0)
        #expect(c.alpha == 1)
    }

    @Test func parsesEightDigitHexWithAlpha() throws {
        let c = try #require(RGBA(hex: "00000080"))
        #expect(abs(c.alpha - 128.0 / 255) < 0.0001)
    }

    @Test func rejectsInvalidHex() {
        #expect(RGBA(hex: "#12345") == nil)
        #expect(RGBA(hex: "zzzzzz") == nil)
        #expect(RGBA(hex: "") == nil)
    }

    @Test func everyThemeHasUniqueName() {
        let names = ThemePalette.all.map(\.name)
        #expect(names.count == 8)
        #expect(Set(names).count == names.count)
    }

    @Test func lookupFallsBackToNord() {
        #expect(ThemePalette.named("catppuccin-latte").name == "catppuccin-latte")
        #expect(ThemePalette.named("does-not-exist").name == ThemePalette.defaultName)
    }

    @Test func derivedColoursUseAlphas() {
        let p = ThemePalette.nord
        #expect(p.panelBackground.alpha == 0.95)
        #expect(p.hover.alpha == 0.8)
        #expect(p.textSecondary.alpha == 0.7)
    }
}
