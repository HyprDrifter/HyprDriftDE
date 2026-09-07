import QtQuick
import QtTest
import "../../quickdrift-shell/Services/ApplicationSearch.js" as Search

TestCase {
    name: "ApplicationSearch"

    function desktopEntry(id, name, options) {
        const metadata = options || ({})
        return {
            id: id,
            name: name,
            genericName: metadata.genericName || "",
            comment: metadata.comment || "",
            keywords: metadata.keywords || [],
            categories: metadata.categories || [],
            icon: metadata.icon || "",
            startupClass: metadata.startupClass || "",
            command: metadata.command || ["/usr/bin/" + id],
            noDisplay: metadata.noDisplay === true
        }
    }

    function records(entries) {
        return Search.recordsFromDesktopEntries(entries)
    }

    function test_normalization() {
        compare(Search.normalizeText("  Café—Déjà!  "), "cafe deja")
        compare(Search.normalizeText("Foo_bar...Baz"), "foo bar baz")
        compare(Search.initials("Visual Studio Code"), "vsc")
        compare(Search.executableName(["/usr/local/bin/firefox", "--new-window"]),
            "firefox")
        compare(Search.applicationLaunchIdentifiers([
            "steam", "steam://rungameid/1170950"
        ])[0], "steam_app_1170950")
    }

    function test_stableAlphabeticalRecords() {
        const indexed = records([
            desktopEntry("zeta.desktop", "Zeta"),
            desktopEntry("alpha-b.desktop", "Alpha"),
            desktopEntry("alpha-a.desktop", "Alpha"),
            desktopEntry("hidden.desktop", "Hidden", { noDisplay: true })
        ])

        compare(indexed.length, 3)
        compare(indexed[0].id, "alpha-a.desktop")
        compare(indexed[1].id, "alpha-b.desktop")
        compare(indexed[2].id, "zeta.desktop")
        compare(indexed[0].baseOrder, 0)
        compare(indexed[2].baseOrder, 2)
    }

    function test_cacheRoundTripAndRecovery() {
        const indexed = records([
            desktopEntry("code.desktop", "Visual Studio Code", {
                genericName: "Code Editor",
                comment: "Edit source code",
                keywords: ["editor", "development"],
                categories: ["Development"],
                icon: "visual-studio-code",
                startupClass: "Code",
                command: ["/opt/visual-studio-code/code", "--unity-launch"]
            })
        ])
        const payload = Search.encodeCache(indexed)
        const decoded = Search.decodeCache(payload)

        verify(decoded.valid)
        compare(decoded.entries.length, 1)
        compare(decoded.entries[0].name, "Visual Studio Code")
        compare(decoded.entries[0].commandName, "code")
        compare(decoded.entries[0].startupClass, "Code")
        compare(decoded.entries[0].available, false)
        compare(decoded.entries[0].liveEntry, null)
        compare(Search.encodeCache(decoded.entries), payload)

        verify(!Search.decodeCache("not json").valid)
        verify(!Search.decodeCache(JSON.stringify({
            schemaVersion: 99,
            entries: []
        })).valid)
        verify(Search.decodeCache("").valid)
    }

    function test_reconciliationInputsAddUpdateAndRemove() {
        const initial = records([
            desktopEntry("alpha.desktop", "Alpha"),
            desktopEntry("beta.desktop", "Beta")
        ])
        const changed = records([
            desktopEntry("beta.desktop", "Beta Updated"),
            desktopEntry("gamma.desktop", "Gamma")
        ])

        compare(initial.length, 2)
        compare(changed.length, 2)
        compare(changed[0].id, "beta.desktop")
        compare(changed[0].name, "Beta Updated")
        compare(changed[1].id, "gamma.desktop")
    }

    function test_runningApplicationResolution() {
        const indexed = records([
            desktopEntry("firefox.desktop", "Firefox", {
                startupClass: "firefox",
                command: ["/usr/bin/firefox"]
            }),
            desktopEntry("com.spotify.Client.desktop", "Spotify", {
                startupClass: "Spotify",
                command: ["/usr/bin/spotify"]
            }),
            desktopEntry("org.gnome.Nautilus.desktop", "Files", {
                command: ["/usr/bin/nautilus"]
            }),
            desktopEntry("org.example.Editor.desktop", "Editor", {
                command: ["/usr/bin/example-editor"]
            })
        ])

        compare(Search.recordForAppId(indexed, "Firefox").id,
            "firefox.desktop")
        compare(Search.recordForAppId(indexed,
            "com.spotify.Client").id, "com.spotify.Client.desktop")
        compare(Search.recordForAppId(indexed,
            "org.gnome.Nautilus").id, "org.gnome.Nautilus.desktop")
        compare(Search.recordForAppId(indexed,
            "/usr/bin/example-editor").id, "org.example.Editor.desktop")
        compare(Search.recordForAppId(indexed, "not-installed"), null)
    }

    function test_nemoResolutionAndIconCandidates() {
        const indexed = records([
            desktopEntry("nemo", "Files", {
                icon: "system-file-manager",
                command: ["/usr/bin/nemo"]
            })
        ])
        const nemo = Search.recordForAppId(indexed, "nemo")

        verify(nemo !== null)
        compare(nemo.id, "nemo")
        compare(Search.iconNameCandidates(nemo), [
            "system-file-manager",
            "nemo"
        ])
    }

    function test_iconCandidatesUseDesktopMetadataFallbacks() {
        const candidateRecord = records([
            desktopEntry("org.example.Editor.desktop", "Editor", {
                startupClass: "ExampleEditor",
                command: ["/opt/editor/bin/example-editor"]
            })
        ])[0]

        compare(Search.iconNameCandidates(candidateRecord), [
            "org.example.Editor",
            "example-editor",
            "ExampleEditor",
            "editor"
        ])
    }

    function test_steamShortcutResolution() {
        const indexed = records([
            desktopEntry("Mortal Online 2.desktop", "Mortal Online 2", {
                icon: "steam_icon_1170950",
                command: ["steam", "steam://rungameid/1170950"]
            }),
            desktopEntry("another-steam-game.desktop", "Another Game", {
                command: ["steam", "-applaunch", "123456"]
            })
        ])

        compare(Search.recordForAppId(indexed,
            "steam_app_1170950").id, "Mortal Online 2.desktop")
        compare(Search.recordForAppId(indexed,
            "STEAM_APP_123456").id, "another-steam-game.desktop")

        const decoded = Search.decodeCache(Search.encodeCache(indexed))
        compare(decoded.entries[1].launchIdentifiers[0],
            "steam_app_1170950")
    }

    function test_ambiguousFallbackDoesNotFalseMatch() {
        const indexed = records([
            desktopEntry("org.alpha.Viewer.desktop", "Viewer"),
            desktopEntry("org.beta.Viewer.desktop", "Viewer")
        ])

        compare(Search.recordForAppId(indexed, "Viewer"), null)
    }

    function test_rankingAcrossFields() {
        const indexed = records([
            desktopEntry("firefox.desktop", "Firefox Web Browser", {
                genericName: "Web Browser",
                keywords: ["internet", "web"],
                categories: ["Network"],
                command: ["/usr/bin/firefox"]
            }),
            desktopEntry("org.gnome.FileRoller.desktop", "File Roller", {
                genericName: "Archive Manager",
                comment: "Create and modify archives"
            }),
            desktopEntry("code.desktop", "Visual Studio Code", {
                genericName: "Source Code Editor",
                keywords: ["editor", "development"],
                command: ["/usr/bin/code"]
            }),
            desktopEntry("steam.desktop", "Steam", {
                categories: ["Game"]
            })
        ])

        compare(Search.rankRecords(indexed, "steam")[0].id, "steam.desktop")
        compare(Search.rankRecords(indexed, "fire")[0].id, "firefox.desktop")
        compare(Search.rankRecords(indexed, "vsc")[0].id, "code.desktop")
        compare(Search.rankRecords(indexed, "editor")[0].id, "code.desktop")
        compare(Search.rankRecords(indexed, "code")[0].id, "code.desktop")
        compare(Search.rankRecords(indexed, "archive")[0].id,
            "org.gnome.FileRoller.desktop")
        compare(Search.rankRecords(indexed, "game")[0].id, "steam.desktop")
        compare(Search.rankRecords(indexed, "visual editor")[0].id,
            "code.desktop")
        compare(Search.rankRecords(indexed, "visual browser").length, 0)
    }

    function test_typosAndShortQueries() {
        const indexed = records([
            desktopEntry("firefox.desktop", "Firefox"),
            desktopEntry("steam.desktop", "Steam")
        ])

        compare(Search.rankRecords(indexed, "firfox")[0].id,
            "firefox.desktop")
        compare(Search.rankRecords(indexed, "firfux")[0].id,
            "firefox.desktop")
        compare(Search.rankRecords(indexed, "stam")[0].id,
            "steam.desktop")
        compare(Search.rankRecords(indexed, "sm").length, 0)
    }

    function test_diacriticsAndDeterministicTies() {
        const indexed = records([
            desktopEntry("zeta.desktop", "Zeta Painter", {
                keywords: ["paint"]
            }),
            desktopEntry("alpha.desktop", "Alpha Painter", {
                keywords: ["paint"]
            }),
            desktopEntry("cafe.desktop", "Café Writer")
        ])

        compare(Search.rankRecords(indexed, "cafe")[0].id, "cafe.desktop")
        const tied = Search.rankRecords(indexed, "paint")
        compare(tied[0].id, "alpha.desktop")
        compare(tied[1].id, "zeta.desktop")
    }

    function test_performanceAcceptance() {
        const synthetic = []
        for (let index = 0; index < 1000; index++) {
            synthetic.push(desktopEntry(
                "synthetic-" + index + ".desktop",
                "Synthetic Application " + index,
                {
                    genericName: "Test Utility",
                    comment: "Synthetic benchmark application",
                    keywords: ["benchmark", "utility", String(index)],
                    categories: ["Utility"]
                }))
        }

        const reconcileStart = Date.now()
        const indexed = records(synthetic)
        const reconcileElapsed = Date.now() - reconcileStart
        compare(indexed.length, 1000)
        verify(reconcileElapsed <= 50,
            "1,000-entry reconciliation took " + reconcileElapsed + "ms")

        const searchStart = Date.now()
        const ranked = Search.rankRecords(indexed, "synthetic 999")
        const searchElapsed = Date.now() - searchStart
        compare(ranked[0].id, "synthetic-999.desktop")
        verify(searchElapsed < 17,
            "1,000-entry search took " + searchElapsed + "ms")
    }
}
