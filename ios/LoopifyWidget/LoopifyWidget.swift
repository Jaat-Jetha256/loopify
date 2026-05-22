import WidgetKit
import SwiftUI

// MARK: - Shared App Group

private let appGroupId = "group.com.loopify.loopify"
private let defaults = UserDefaults(suiteName: appGroupId)

// MARK: - Data Model

struct LoopifyEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let habitsCompleted: Int
    let quip: String
    let imageName: String
    let lastUpdate: Date?
    let hasLiveData: Bool

    static var placeholder: LoopifyEntry {
        LoopifyEntry(
            date: Date(),
            streak: 7,
            habitsCompleted: 4,
            quip: "Let's build something",
            imageName: "widget_2",
            lastUpdate: Date(),
            hasLiveData: true
        )
    }
}

// MARK: - Provider

struct LoopifyProvider: TimelineProvider {
    func placeholder(in context: Context) -> LoopifyEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (LoopifyEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LoopifyEntry>) -> Void) {
        let entry = currentEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> LoopifyEntry {
        // Prefer keychain (survives iLoader re-sign); fall back to app-group
        // UserDefaults if a future, properly-entitled build is installed.
        let rawImage = WidgetKeychainStore.getString(forKey: "image")
            ?? defaults?.string(forKey: "image")
        let rawQuip = WidgetKeychainStore.getString(forKey: "quip")
            ?? defaults?.string(forKey: "quip")
        let lastUpdateISO = WidgetKeychainStore.getString(forKey: "last_update")
            ?? defaults?.string(forKey: "last_update")
        let hasLive = rawImage != nil || rawQuip != nil || lastUpdateISO != nil

        let streak = WidgetKeychainStore.getInt(forKey: "streak")
            ?? defaults?.integer(forKey: "streak") ?? 0
        let habits = WidgetKeychainStore.getInt(forKey: "habits_completed")
            ?? defaults?.integer(forKey: "habits_completed") ?? 0
        let quip = rawQuip ?? "Open Loopify to sync"
        let raw = rawImage ?? "1.png"

        let mapped: String
        switch raw {
        case "2.png": mapped = "widget_2"
        case "3.png": mapped = "widget_3"
        default:      mapped = "widget_1"
        }

        let parsedDate: Date? = lastUpdateISO.flatMap {
            ISO8601DateFormatter().date(from: $0)
        }

        return LoopifyEntry(
            date: Date(),
            streak: streak,
            habitsCompleted: habits,
            quip: quip,
            imageName: mapped,
            lastUpdate: parsedDate,
            hasLiveData: hasLive
        )
    }
}

// MARK: - Brand

private enum Brand {
    static let accent = Color(red: 1.00, green: 0.478, blue: 0.184)      // 0xFFFF7A2F
    static let accentDeep = Color(red: 0.878, green: 0.322, blue: 0.114) // 0xFFE0521D
    static let bgDeep = Color(red: 0.020, green: 0.024, blue: 0.059)     // 0xFF05060F
    static let bgMid = Color(red: 0.043, green: 0.051, blue: 0.141)      // 0xFF0B0D24
}

// MARK: - View

struct LoopifyWidgetView: View {
    let entry: LoopifyEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack {
            backgroundLayer
            content
        }
        .widgetURL(URL(string: "loopify://open"))
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Brand.bgDeep, Brand.bgMid, Brand.bgDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft accent glow orb (top-right)
            Circle()
                .fill(Brand.accent.opacity(0.35))
                .frame(width: 180, height: 180)
                .blur(radius: 60)
                .offset(x: 70, y: -60)

            // Faint vignette
            Color.black.opacity(0.18)
        }
        .overlay(
            // Hairline glass border
            ContainerRelativeShape()
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var content: some View {
        HStack(spacing: 12) {
            iconCard
            VStack(alignment: .leading, spacing: 5) {
                streakBadge
                Text(entry.quip)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                progressBar
                statusLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
    }

    private var statusLine: some View {
        Group {
            if entry.hasLiveData, let last = entry.lastUpdate {
                Text("Updated \(Self.relative.localizedString(for: last, relativeTo: Date()))")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .lineLimit(1)
            } else {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.yellow.opacity(0.8))
                        .frame(width: 5, height: 5)
                    Text("No data — open app once")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
        }
    }

    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private var iconCard: some View {
        ZStack {
            // Frosted plate
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )

            Image(entry.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
        }
        .frame(width: 58, height: 58)
        .shadow(color: Brand.accent.opacity(0.25), radius: 10, x: 0, y: 4)
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.system(size: 14))
            Text("\(entry.streak)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Brand.accent, Brand.accentDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Brand.accent.opacity(0.6), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Brand.accent.opacity(0.14))
                .overlay(
                    Capsule()
                        .stroke(Brand.accent.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Brand.accent, Brand.accentDeep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progressFraction)
                    .shadow(color: Brand.accent.opacity(0.45), radius: 4, x: 0, y: 1)
            }
        }
        .frame(height: 5)
    }

    private var progressFraction: CGFloat {
        let max: CGFloat = 11
        let v = min(CGFloat(entry.habitsCompleted), max)
        return v / max
    }
}

// MARK: - Widget

struct LoopifyWidget: Widget {
    let kind: String = "LoopifyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LoopifyProvider()) { entry in
            if #available(iOS 17.0, *) {
                LoopifyWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.clear
                    }
            } else {
                LoopifyWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Loopify Streak")
        .description("Keep your fire alive — streak, progress, and a nudge.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Bundle

@main
struct LoopifyWidgetBundle: WidgetBundle {
    var body: some Widget {
        LoopifyWidget()
    }
}

// MARK: - Preview

#if DEBUG
struct LoopifyWidget_Previews: PreviewProvider {
    static var previews: some View {
        LoopifyWidgetView(entry: .placeholder)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
#endif
