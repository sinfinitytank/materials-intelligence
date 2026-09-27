import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum MITheme {
    static let accent = Color(red: 0.13, green: 0.38, blue: 0.45)
    static let selected = accent.opacity(0.10)
    static let canvas: Color = {
        #if os(macOS)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }()
    static let sidebar: Color = {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor).opacity(0.58)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }()
    static let surface: Color = {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }()
    static let subtleSurface = Color.primary.opacity(0.035)
    static let separator = Color.primary.opacity(0.085)
    static let success = Color.green
    static let caution = Color.orange
    static let danger = Color.red
    static let information = accent

    enum Space {
        static let tight: CGFloat = 4
        static let compact: CGFloat = 8
        static let regular: CGFloat = 12
        static let panel: CGFloat = 16
        static let page: CGFloat = 20
        static let inset: CGFloat = {
            #if os(iOS)
            20
            #else
            28
            #endif
        }()
    }

    enum Radius {
        static let control: CGFloat = 8
        static let selection: CGFloat = 7
        static let panel: CGFloat = 10
        static let prominent: CGFloat = 12
    }

    enum Typography {
        static let pageTitle = Font.system(size: 26, weight: .semibold)
        static let pageSubtitle = Font.system(size: 13)
        static let sectionTitle = Font.system(size: 14, weight: .semibold)
        static let body = Font.system(size: 14)
        static let supporting = Font.system(size: 13)
        static let metadata = Font.system(size: 12)
        static let navigation = Font.system(size: 13)
        static let metricValue = Font.system(size: 26, weight: .semibold, design: .rounded)
    }

    static let pageInset = Space.inset
    static let panelInset: CGFloat = 16
    static let sectionGap: CGFloat = Space.regular
    static let panelRadius = Radius.panel

    static func categoryColor(for kind: RecordKind) -> Color {
        switch kind {
        case .material: accent
        case .mechanism: caution
        case .standard: Color.indigo
        case .component: Color.teal
        case .source: Color.secondary
        }
    }

    static func statusColor(for status: VerificationStatus) -> Color {
        switch status {
        case .verified: success
        case .reviewed: information
        case .draft, .unverified: caution
        case .superseded, .archived: Color.secondary
        }
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(MITheme.panelInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MITheme.surface, in: RoundedRectangle(cornerRadius: MITheme.panelRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: MITheme.panelRadius, style: .continuous).stroke(MITheme.separator, lineWidth: 0.7))
    }
}

struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: MITheme.Space.tight) {
            Text(title).font(MITheme.Typography.pageTitle)
            Text(subtitle).font(MITheme.Typography.pageSubtitle).foregroundStyle(.secondary)
        }
    }
}

struct SectionTitle: View {
    let title: String
    let icon: String

    init(_ title: String, icon: String) {
        self.title = title
        self.icon = icon
    }

    init(title: String, icon: String) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        Label(title, systemImage: icon)
            .font(MITheme.Typography.sectionTitle)
            .foregroundStyle(MITheme.accent)
    }
}

struct StatusBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(MITheme.Typography.metadata.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, MITheme.Space.compact)
            .padding(.vertical, MITheme.Space.tight)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: MITheme.Radius.control, style: .continuous))
    }
}
