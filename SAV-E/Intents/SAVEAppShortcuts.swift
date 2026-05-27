import AppIntents

struct SAVEAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SavePlaceFromURLIntent(),
            phrases: [
                "Save this place to \(.applicationName)",
                "Add this URL to \(.applicationName)",
                "\(.applicationName) save this place"
            ],
            shortTitle: "Save URL",
            systemImageName: "tray.and.arrow.down"
        )

        AppShortcut(
            intent: AskSaveMemoryIntent(),
            phrases: [
                "Ask \(.applicationName) memory",
                "What did I save in \(.applicationName)",
                "\(.applicationName) recent memory"
            ],
            shortTitle: "Ask Memory",
            systemImageName: "sparkles"
        )
    }
}
