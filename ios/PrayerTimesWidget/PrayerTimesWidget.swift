import WidgetKit
import SwiftUI

struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            PrayerTimesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("View today's prayer times on your lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let nextPrayer: String
    let location: String
}

struct PrayerTimesProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimesEntry {
        PrayerTimesEntry(
            date: Date(),
            fajr: "5:30",
            dhuhr: "12:30",
            asr: "16:00",
            maghrib: "19:00",
            isha: "20:30",
            nextPrayer: "Subuh",
            location: "Kuala Lumpur"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> ()) {
        let entry = getCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimesEntry>) -> ()) {
        let entry = getCurrentEntry()
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getCurrentEntry() -> PrayerTimesEntry {
        // Fetch prayer times from App Group UserDefaults (shared with Flutter app)
        let userDefaults = UserDefaults(suiteName: "group.com.hexahelix.dq")
        
        return PrayerTimesEntry(
            date: Date(),
            fajr: userDefaults?.string(forKey: "fajr") ?? "5:30",
            dhuhr: userDefaults?.string(forKey: "dhuhr") ?? "12:30",
            asr: userDefaults?.string(forKey: "asr") ?? "16:00",
            maghrib: userDefaults?.string(forKey: "maghrib") ?? "19:00",
            isha: userDefaults?.string(forKey: "isha") ?? "20:30",
            nextPrayer: userDefaults?.string(forKey: "nextPrayer") ?? "Subuh",
            location: userDefaults?.string(forKey: "location") ?? ""
        )
    }
}

@available(iOS 16.0, *)
struct PrayerTimesWidgetEntryView: View {
    var entry: PrayerTimesProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 2) {
                Text(entry.nextPrayer)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(entry.fajr)
                    .font(.caption2)
            }
        case .accessoryRectangular:
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next: \(entry.nextPrayer)")
                        .font(.headline)
                    Text("F:\(entry.fajr) D:\(entry.dhuhr) A:\(entry.asr) M:\(entry.maghrib) I:\(entry.isha)")
                        .font(.caption2)
                }
                Spacer()
            }
        case .accessoryInline:
            Text("\(entry.nextPrayer): \(entry.fajr)")
        default:
            Text("Prayer Times")
        }
    }
}

@main
struct PrayerTimesWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
    }
}


