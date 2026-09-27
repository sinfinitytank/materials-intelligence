import AppKit
import ApplicationServices
import CoreGraphics
import Darwin
import Foundation

private struct AcceptanceFailure: Error, CustomStringConvertible {
    let description: String
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw AcceptanceFailure(description: message) }
}

private func attribute(_ element: AXUIElement, _ name: String) -> Any? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
}

private func stringAttribute(_ element: AXUIElement, _ name: String) -> String {
    (attribute(element, name) as? String) ?? ""
}

private func children(_ element: AXUIElement) -> [AXUIElement] {
    (attribute(element, kAXChildrenAttribute as String) as? [AXUIElement]) ?? []
}

private func findElement(
    from root: AXUIElement,
    depthLimit: Int = 30,
    elementLimit: Int = 4_000,
    matching predicate: (AXUIElement) -> Bool
) -> AXUIElement? {
    func visit(_ element: AXUIElement, depth: Int, remaining: inout Int) -> AXUIElement? {
        guard depth <= depthLimit, remaining > 0 else { return nil }
        remaining -= 1
        if predicate(element) { return element }
        for child in children(element) {
            if let match = visit(child, depth: depth + 1, remaining: &remaining) { return match }
        }
        return nil
    }

    var remaining = elementLimit
    return visit(root, depth: 0, remaining: &remaining)
}

private func allElements(from root: AXUIElement, depthLimit: Int = 30, elementLimit: Int = 4_000) -> [AXUIElement] {
    func visit(_ element: AXUIElement, depth: Int, remaining: inout Int, output: inout [AXUIElement]) {
        guard depth <= depthLimit, remaining > 0 else { return }
        remaining -= 1
        output.append(element)
        for child in children(element) { visit(child, depth: depth + 1, remaining: &remaining, output: &output) }
    }

    var remaining = elementLimit
    var result: [AXUIElement] = []
    visit(root, depth: 0, remaining: &remaining, output: &result)
    return result
}

private func applicationWindow(for pid: pid_t) -> AXUIElement? {
    let application = AXUIElementCreateApplication(pid)
    if let mainWindow = attribute(application, kAXMainWindowAttribute as String) {
        return (mainWindow as! AXUIElement)
    }
    if let windows = attribute(application, kAXWindowsAttribute as String) as? [AXUIElement] {
        return windows.first
    }
    return nil
}

private func identifier(_ value: String, existsIn pid: pid_t) -> Bool {
    guard let window = applicationWindow(for: pid) else { return false }
    return findElement(from: window) { stringAttribute($0, kAXIdentifierAttribute as String) == value } != nil
}

private func textIsVisible(_ value: String, in pid: pid_t) -> Bool {
    guard let window = applicationWindow(for: pid) else { return false }
    return findElement(from: window) {
        stringAttribute($0, kAXRoleAttribute as String) == kAXStaticTextRole as String
            && (attribute($0, kAXValueAttribute as String) as? String) == value
    } != nil
}

private func waitUntil(
    _ message: String,
    timeout: TimeInterval = 4,
    condition: () -> Bool
) -> Bool {
    let end = Date().addingTimeInterval(timeout)
    repeat {
        if condition() { return true }
        Thread.sleep(forTimeInterval: 0.05)
    } while Date() < end
    print("FAIL \(message)")
    return false
}

private func performPress(_ element: AXUIElement, _ description: String) throws {
    let result = AXUIElementPerformAction(element, kAXPressAction as CFString)
    try require(result == .success, "Accessibility press failed for \(description): \(result)")
}

private func pressIdentifier(_ identifier: String, in pid: pid_t) throws {
    func matchingElement() -> AXUIElement? {
        guard let window = applicationWindow(for: pid) else { return nil }
        return findElement(from: window, matching: {
              stringAttribute($0, kAXIdentifierAttribute as String) == identifier
        })
    }

    var element = matchingElement()
    if element == nil, identifier.hasPrefix("navigation.") {
        _ = waitUntil("Navigation target \(identifier) did not settle", timeout: 0.35) {
            matchingElement() != nil
        }
        element = matchingElement()
    }
    if element == nil, identifier.hasPrefix("navigation.") {
        if let window = applicationWindow(for: pid),
           let showSidebar = findElement(from: window, matching: {
               stringAttribute($0, kAXDescriptionAttribute as String) == "Show Sidebar"
           }) {
            try performPress(showSidebar, "show navigation sidebar")
            _ = waitUntil("Navigation sidebar did not reopen") { matchingElement() != nil }
            element = matchingElement()
        }
    }
    if element == nil, identifier.hasPrefix("navigation.") {
        guard let window = applicationWindow(for: pid) else {
            throw AcceptanceFailure(description: "Navigation window is unavailable for \(identifier)")
        }
        guard let sidebarScrollArea = findElement(from: window, matching: { candidate in
                  stringAttribute(candidate, kAXRoleAttribute as String) == kAXScrollAreaRole as String
                      && findElement(from: candidate, matching: {
                          let value = stringAttribute($0, kAXIdentifierAttribute as String)
                          return value.hasPrefix("navigation.") && value != "navigation.settings"
                      }) != nil
              }) else {
            let ids = ["navigation.overview", "navigation.relationships", "navigation.assessment", "navigation.personalVault"]
                .filter { expected in findElement(from: window, matching: {
                    stringAttribute($0, kAXIdentifierAttribute as String) == expected
                }) != nil }
            let areas = allElements(from: window).filter { stringAttribute($0, kAXRoleAttribute as String) == kAXScrollAreaRole as String }
                .map { "\(stringAttribute($0, kAXIdentifierAttribute as String)):\(children($0).count)" }
            let toolbarButtons = allElements(from: window)
                .filter { stringAttribute($0, kAXRoleAttribute as String) == kAXButtonRole as String }
                .map { "\(stringAttribute($0, kAXIdentifierAttribute as String)):\(stringAttribute($0, kAXDescriptionAttribute as String)):\(stringAttribute($0, kAXSubroleAttribute as String))" }
            print("UI acceptance failure context — navigation target=\(identifier) ids=\(ids) scrollAreas=\(areas) window=\(stringAttribute(window, kAXRoleAttribute as String))/\(stringAttribute(window, kAXSubroleAttribute as String))/\(stringAttribute(window, kAXTitleAttribute as String)) toolbarButtons=\(toolbarButtons)")
            throw AcceptanceFailure(description: "Navigation sidebar is unavailable for \(identifier)")
        }
        for _ in 0..<6 {
            _ = AXUIElementPerformAction(sidebarScrollArea, "AXScrollUpByPage" as CFString)
            Thread.sleep(forTimeInterval: 0.025)
        }
        for _ in 0..<8 {
            element = matchingElement()
            if element != nil { break }
            _ = AXUIElementPerformAction(sidebarScrollArea, "AXScrollDownByPage" as CFString)
            Thread.sleep(forTimeInterval: 0.05)
        }
        element = element ?? matchingElement()
    }

    guard let element else {
        throw AcceptanceFailure(description: "Missing accessibility identifier: \(identifier)")
    }
    try performPress(element, identifier)
}

private func windowSize(_ window: AXUIElement) -> CGSize? {
    guard let raw = attribute(window, kAXSizeAttribute as String) else { return nil }
    var size = CGSize.zero
    guard AXValueGetValue(raw as! AXValue, .cgSize, &size) else { return nil }
    return size
}

private func isFullScreen(_ window: AXUIElement) -> Bool? {
    guard let value = attribute(window, "AXFullScreen") as? NSNumber else { return nil }
    return value.boolValue
}

private func processIsAlive(_ pid: pid_t) -> Bool {
    kill(pid, 0) == 0 || errno == EPERM
}

private func hasOnScreenWindow(_ pid: pid_t) -> Bool {
    let rows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    return rows.contains { row in
        guard let owner = row[kCGWindowOwnerPID as String] as? NSNumber else { return false }
        return owner.int32Value == pid
    }
}

private func processIDs(bundleID: String, appPath: String) -> [pid_t] {
    let expectedPath = URL(fileURLWithPath: appPath).standardizedFileURL.path
    return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        .filter { !$0.isTerminated && $0.bundleURL?.standardizedFileURL.path == expectedPath }
        .map(\.processIdentifier)
}

private func runOpen(_ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()
    try require(process.terminationStatus == 0, "Launch Services failed: open \(arguments.joined(separator: " "))")
}

private func currentTextValue(_ element: AXUIElement) -> String {
    if let value = attribute(element, kAXValueAttribute as String) as? String { return value }
    return stringAttribute(element, kAXDescriptionAttribute as String)
}

private func runAcceptance() throws {
    guard CommandLine.arguments.count == 5,
          let initialPID = pid_t(CommandLine.arguments[1]) else {
        throw AcceptanceFailure(description: "Usage: ui-acceptance.swift <pid> <app-path> <support-path> <bundle-id>")
    }

    let appPath = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL.path
    let supportPath = URL(fileURLWithPath: CommandLine.arguments[3]).standardizedFileURL.path
    let bundleID = CommandLine.arguments[4]
    var pid = initialPID
    try require(waitUntil("The app did not publish an accessible window", timeout: 10) {
        applicationWindow(for: pid) != nil && hasOnScreenWindow(pid)
    }, "The launched app has no accessible main window")
    try require(AXIsProcessTrusted(), "Accessibility permission is not available to this test process")
    try require(processIsAlive(pid), "The app process exited before UI acceptance started")
    guard let initialWindow = applicationWindow(for: pid) else {
        throw AcceptanceFailure(description: "The launched app has no accessible main window")
    }
    try require(stringAttribute(initialWindow, kAXRoleAttribute as String) == kAXWindowRole as String, "The main surface is not a standard window")
    try require(stringAttribute(initialWindow, kAXSubroleAttribute as String) == kAXStandardWindowSubrole as String, "The main surface does not expose a standard macOS window")
    try require(stringAttribute(initialWindow, kAXTitleAttribute as String) == "Materials Intelligence", "Unexpected initial window title")
    try require(isFullScreen(initialWindow) == false, "The app opened in Full Screen")
    var canResize = DarwinBoolean(false)
    let resizeQuery = AXUIElementIsAttributeSettable(initialWindow, kAXSizeAttribute as CFString, &canResize)
    try require(resizeQuery == .success && canResize.boolValue, "The window does not expose a resizable size")
    print("PASS launch: standard window, windowed, process \(pid)")

    let sizes = [
        ("compact", CGSize(width: 1_120, height: 700)),
        ("medium", CGSize(width: 1_320, height: 820)),
        ("large", CGSize(width: 1_450, height: 900)),
    ]
    let sections = [
        "overview", "ask", "search", "explorer", "research", "materials", "mechanisms", "components",
        "standards", "sources", "library", "claims", "relationships", "assessment", "agent",
        "personalVault", "settings",
    ]

    for (sizeName, requestedSize) in sizes {
        guard let window = applicationWindow(for: pid) else {
            throw AcceptanceFailure(description: "Main window disappeared before \(sizeName) resize")
        }
        var size = requestedSize
        guard let axSize = AXValueCreate(.cgSize, &size) else {
            throw AcceptanceFailure(description: "Could not create accessibility size for \(sizeName)")
        }
        let setResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, axSize)
        try require(setResult == .success, "Could not resize the window to \(sizeName): \(setResult)")
        Thread.sleep(forTimeInterval: 0.2)
        guard let actualSize = windowSize(applicationWindow(for: pid) ?? window) else {
            throw AcceptanceFailure(description: "Could not read the \(sizeName) window size")
        }
        try require(actualSize.width >= 1_040 && actualSize.height >= 680, "The \(sizeName) window violated the content minimum: \(actualSize)")
        try require(actualSize.width > 1_100 && actualSize.height > 700, "The \(sizeName) window did not accept a useful desktop size: \(actualSize)")
        try require(isFullScreen(applicationWindow(for: pid) ?? window) == false, "The \(sizeName) resize entered Full Screen")
        print("PASS resize \(sizeName): requested \(Int(requestedSize.width))×\(Int(requestedSize.height)), actual \(Int(actualSize.width))×\(Int(actualSize.height))")

        for section in sections + sections.reversed() {
            try pressIdentifier("navigation.\(section)", in: pid)
            let pageID = "workspace.page.\(section)"
            try require(waitUntil("route \(section) was not rendered at \(sizeName)") {
                identifier(pageID, existsIn: pid)
            }, "Route did not render: \(section)")
            Thread.sleep(forTimeInterval: 0.12)
            try require(processIsAlive(pid), "The app process exited while navigating to \(section)")
        }
        print("PASS global navigation at \(sizeName): \(sections.count * 2) route transitions")
    }

    guard let window = applicationWindow(for: pid) else {
        throw AcceptanceFailure(description: "Main window disappeared before minimum-size check")
    }
    var undersizedRequest = CGSize(width: 900, height: 600)
    let minimumSize = AXValueCreate(.cgSize, &undersizedRequest)!
    try require(AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, minimumSize) == .success, "The minimum-size request was rejected")
    Thread.sleep(forTimeInterval: 0.25)
    guard let clampedSize = windowSize(applicationWindow(for: pid) ?? window) else {
        throw AcceptanceFailure(description: "Could not read the minimum-size result")
    }
    try require(clampedSize.width >= 1_040 && clampedSize.height >= 680, "The window shrank below its declared content minimum: \(clampedSize)")
    print("PASS minimum size: 900×600 request clamped to \(Int(clampedSize.width))×\(Int(clampedSize.height))")

    try pressIdentifier("navigation.personalVault", in: pid)
    let referenceLoaded = waitUntil("Private Vault reference tab did not load", timeout: 8) {
        identifier("personalVault.reference.add", existsIn: pid)
    }
    if !referenceLoaded, let current = applicationWindow(for: pid) {
        let state = allElements(from: current).map { element in
            let role = stringAttribute(element, kAXRoleAttribute as String)
            let id = stringAttribute(element, kAXIdentifierAttribute as String)
            let title = stringAttribute(element, kAXTitleAttribute as String)
            let value = currentTextValue(element)
            return "\(role):\(id):\(title):\(value)"
        }
        print("UI acceptance failure context — Personal Vault: page=\(identifier("workspace.page.personalVault", existsIn: pid)) state=\(state.filter { $0.contains("personalVault") || $0.contains("No references") || $0.contains("vault") || $0.contains("Loading") || $0.contains("unavailable") })")
    }
    try require(referenceLoaded, "Private Vault did not load its reference tab")

    let tabs: [(id: String, label: String, marker: String)] = [
        ("reference", "Reference", "personalVault.reference.add"),
        ("ask", "Ask", "personalVault.ask.question"),
        ("sync", "Sync", "personalVault.sync.status"),
        ("research", "Research review", "personalVault.research.content"),
        ("claims", "Claims", "personalVault.claims.content"),
        ("relationships", "Relationships", "No relationships yet"),
    ]

    func selectVaultTab(_ tab: (id: String, label: String, marker: String), verify: Bool) throws {
        if let root = applicationWindow(for: pid),
           let radio = findElement(from: root, matching: {
               stringAttribute($0, kAXIdentifierAttribute as String) == "personalVault.tab.\(tab.id)"
           }) {
            try performPress(radio, "Private Vault \(tab.label) tab")
        } else {
            if let root = applicationWindow(for: pid),
               let menuItem = findElement(from: root, matching: {
                   stringAttribute($0, kAXRoleAttribute as String) == kAXMenuItemRole as String
                       && stringAttribute($0, kAXTitleAttribute as String) == tab.label
               }) {
                try performPress(menuItem, "Private Vault \(tab.label) overflow tab")
            } else {
                guard let root = applicationWindow(for: pid),
                      let overflow = findElement(from: root, matching: {
                          stringAttribute($0, kAXDescriptionAttribute as String) == "more toolbar items"
                      }) else {
                    throw AcceptanceFailure(description: "Private Vault tab control is unavailable for \(tab.label)")
                }
                try performPress(overflow, "Private Vault tab overflow menu")
                guard waitUntil("Private Vault overflow did not show \(tab.label)", condition: {
                    guard let current = applicationWindow(for: pid) else { return false }
                    return findElement(from: current, matching: {
                        stringAttribute($0, kAXRoleAttribute as String) == kAXMenuItemRole as String
                            && stringAttribute($0, kAXTitleAttribute as String) == tab.label
                    }) != nil
                }), let current = applicationWindow(for: pid),
                   let menuItem = findElement(from: current, matching: {
                       stringAttribute($0, kAXRoleAttribute as String) == kAXMenuItemRole as String
                           && stringAttribute($0, kAXTitleAttribute as String) == tab.label
                   }) else {
                    throw AcceptanceFailure(description: "Private Vault overflow item is missing: \(tab.label)")
                }
                try performPress(menuItem, "Private Vault \(tab.label) overflow tab")
            }
        }

        if verify {
            try require(waitUntil("Private Vault \(tab.label) content did not become active") {
                if tab.id == "relationships" { return textIsVisible(tab.marker, in: pid) }
                return identifier(tab.marker, existsIn: pid)
            }, "Private Vault tab content is missing: \(tab.label)")
            try require(processIsAlive(pid), "The app process exited on the \(tab.label) tab")
            print("PASS Private Vault tab: \(tab.label)")
        }
    }

    for (index, tab) in tabs.enumerated() {
        try selectVaultTab(tab, verify: true)
        if index == 0 {
            guard let root = applicationWindow(for: pid),
                  let addReference = findElement(from: root, matching: {
                      stringAttribute($0, kAXIdentifierAttribute as String) == "personalVault.reference.add"
                  }) else {
                throw AcceptanceFailure(description: "Private Vault Add reference control is missing")
            }
            try performPress(addReference, "Private Vault Add reference")
            try require(waitUntil("Private Vault reference editor did not open") {
                identifier("personalVault.reference.name", existsIn: pid)
            }, "Private Vault reference editor did not open")
            guard let editor = applicationWindow(for: pid),
                  let cancel = findElement(from: editor, matching: {
                      stringAttribute($0, kAXIdentifierAttribute as String) == "personalVault.reference.cancel"
                  }) else {
                throw AcceptanceFailure(description: "Private Vault reference editor Cancel control is missing")
            }
            try performPress(cancel, "Private Vault reference editor Cancel")
            try require(waitUntil("Private Vault reference editor did not close") {
                !identifier("personalVault.reference.name", existsIn: pid)
            }, "Private Vault reference editor did not close")
            print("PASS Private Vault reference editor: opened and cancelled without saving")
        }
    }
    for tab in tabs.reversed() { try selectVaultTab(tab, verify: true) }
    for tab in tabs { try selectVaultTab(tab, verify: false); Thread.sleep(forTimeInterval: 0.04) }
    let finalTab = tabs.last!
    try require(waitUntil("Rapid Private Vault switching did not settle on Relationships") {
        textIsVisible(finalTab.marker, in: pid)
    }, "Rapid Private Vault switching left an invalid page")
    try require(processIsAlive(pid), "The app process exited during rapid Private Vault switching")
    print("PASS Private Vault rapid switching: six tabs, process and content survived")

    try selectVaultTab(tabs[2], verify: true)
    guard let statusElement = applicationWindow(for: pid).flatMap({ root in
        findElement(from: root, matching: { stringAttribute($0, kAXIdentifierAttribute as String) == "personalVault.sync.status" })
    }) else {
        throw AcceptanceFailure(description: "Private Sync status is not accessible")
    }
    let offlineStatus = currentTextValue(statusElement)
    try require(offlineStatus.contains("Offline") || offlineStatus.contains("Up to date"), "Unexpected initial sync status: \(offlineStatus)")
    print("PASS sync tab baseline: \(offlineStatus)")

    let infoURL = URL(fileURLWithPath: appPath).appending(path: "Contents/Info.plist")
    let infoData = try Data(contentsOf: infoURL)
    let appInfo = try PropertyListSerialization.propertyList(from: infoData, format: nil) as? [String: Any] ?? [:]
    let cloudEnabled = appInfo["MICloudEnabled"] as? Bool == true
    if cloudEnabled {
        print("BLOCKED synthetic CloudKit UI probe: this app declares MICloudEnabled; no real sync was initiated")
    } else {
        guard let root = applicationWindow(for: pid),
              let consent = findElement(from: root, matching: {
                  stringAttribute($0, kAXIdentifierAttribute as String) == "personalVault.sync.consent"
              }) else {
            throw AcceptanceFailure(description: "Private Sync consent control is missing")
        }
        try performPress(consent, "Private Sync consent toggle")
        try require(waitUntil("Private Sync consent did not change") {
            guard let current = applicationWindow(for: pid),
                  let toggle = findElement(from: current, matching: {
                      stringAttribute($0, kAXIdentifierAttribute as String) == "personalVault.sync.consent"
                  }), let value = attribute(toggle, kAXValueAttribute as String) as? NSNumber else { return false }
            return value.boolValue
        }, "Private Sync consent was not retained")
        try pressIdentifier("personalVault.sync.start", in: pid)
        try require(waitUntil("The unconfigured CloudKit path did not report its blocker", timeout: 6) {
            guard let current = applicationWindow(for: pid),
                  let status = findElement(from: current, matching: {
                      stringAttribute($0, kAXIdentifierAttribute as String) == "personalVault.sync.status"
                  }) else { return false }
            return currentTextValue(status).contains("CloudKit is not configured in this development build")
        }, "The unconfigured CloudKit path did not return the expected local error")
        print("PASS sync error state: CloudKit configuration guard returned before transport")

        try selectVaultTab(tabs[1], verify: true)
        try selectVaultTab(tabs[2], verify: true)
        guard let current = applicationWindow(for: pid),
              let status = findElement(from: current, matching: {
                  stringAttribute($0, kAXIdentifierAttribute as String) == "personalVault.sync.status"
              }),
              let consent = findElement(from: current, matching: {
                  stringAttribute($0, kAXIdentifierAttribute as String) == "personalVault.sync.consent"
              }), let consentValue = attribute(consent, kAXValueAttribute as String) as? NSNumber else {
            throw AcceptanceFailure(description: "Sync state was not retained after tab navigation")
        }
        try require(currentTextValue(status).contains("CloudKit is not configured in this development build"), "Sync error state was recreated or cleared on tab navigation")
        try require(consentValue.boolValue, "Sync consent state was lost when leaving and returning to Sync")
        try require(findElement(from: current, matching: {
            stringAttribute($0, kAXIdentifierAttribute as String) == "personalVault.sync.applyRemote"
        }) == nil, "An incoming snapshot appeared without CloudKit data")
        print("PASS tab lifecycle: sync status and consent survived leaving and returning")
    }

    guard let closeWindow = applicationWindow(for: pid).flatMap({ root in
        findElement(from: root, matching: { stringAttribute($0, kAXSubroleAttribute as String) == kAXCloseButtonSubrole as String })
    }) else {
        throw AcceptanceFailure(description: "The standard window close control is unavailable")
    }
    try performPress(closeWindow, "main window close button")
    try require(waitUntil("The app window did not close") { !hasOnScreenWindow(pid) }, "The app window remained open after Close")
    try require(processIsAlive(pid), "Closing the main window terminated the app process")
    print("PASS close window: process remained alive")

    try runOpen(["-a", appPath, "--args", "--mi-test-application-support=\(supportPath)"])
    var reopenedPID: pid_t?
    let sameProcessReopened = waitUntil("Launch Services did not reopen the window in the running process", timeout: 3) {
        guard processIsAlive(pid), applicationWindow(for: pid) != nil, hasOnScreenWindow(pid) else { return false }
        reopenedPID = pid
        return true
    }
    if !sameProcessReopened {
        try runOpen(["-n", appPath, "--args", "--mi-test-application-support=\(supportPath)"])
        let appeared = waitUntil("A fresh app launch did not reopen the window", timeout: 5) {
            let pids = processIDs(bundleID: bundleID, appPath: appPath)
            if let candidate = pids.last, applicationWindow(for: candidate) != nil, hasOnScreenWindow(candidate) {
                reopenedPID = candidate
                return true
            }
            return false
        }
        try require(appeared, "The app did not reopen after closing its window")
    }

    guard let activePID = reopenedPID, let reopenedWindow = applicationWindow(for: activePID) else {
        throw AcceptanceFailure(description: "No accessible window after reopening")
    }
    pid = activePID
    try require(stringAttribute(reopenedWindow, kAXSubroleAttribute as String) == kAXStandardWindowSubrole as String, "Reopened surface is not a standard window")
    try require(isFullScreen(reopenedWindow) == false, "The reopened app entered Full Screen")
    try require(processIsAlive(activePID), "The reopened app process is not alive")
    if let overview = findElement(from: reopenedWindow, matching: {
        stringAttribute($0, kAXIdentifierAttribute as String) == "navigation.overview"
    }) {
        try performPress(overview, "Overview after window reopen")
        try require(waitUntil("Overview did not render after window reopen") {
            identifier("workspace.page.overview", existsIn: activePID)
        }, "Overview is unavailable after window reopen")
    }
    print("PASS close/reopen: new standard window, \(sameProcessReopened ? "same process" : "new app launch")")

    let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        .filter { $0.bundleURL?.standardizedFileURL.path == appPath }
    for application in running { _ = application.terminate() }
    Thread.sleep(forTimeInterval: 0.5)
    for application in running where !application.isTerminated { application.forceTerminate() }
    print("PASS UI acceptance completed")
}

do {
    try runAcceptance()
} catch {
    fputs("FAIL UI acceptance: \(error)\n", stderr)
    exit(EXIT_FAILURE)
}
