// GENERATED CODE - DO NOT MODIFY BY HAND
//
// Placeholder SwiftUI widget.
//
// App Group ID used here: GreetingHomeWidgetFlavor.appGroupId

import SwiftUI
import WidgetKit

enum GreetingHomeWidgetFlavor {
  static let appGroupId = "group.com.example.app"
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> GreetingHomeWidgetEntry {
    GreetingHomeWidgetEntry(date: Date(), data: GreetingData.fromUserDefaults(nil))
  }

  func getSnapshot(in context: Context, completion: @escaping (GreetingHomeWidgetEntry) -> Void) {
    let prefs = UserDefaults(suiteName: GreetingHomeWidgetFlavor.appGroupId)
    let data = GreetingData.fromUserDefaults(prefs)

    completion(GreetingHomeWidgetEntry(date: Date(), data: data))

  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let prefs = UserDefaults(suiteName: GreetingHomeWidgetFlavor.appGroupId)
    let data = GreetingData.fromUserDefaults(prefs)

    completion(Timeline(entries: [GreetingHomeWidgetEntry(date: Date(), data: data)], policy: .atEnd))

  }
}

struct GreetingHomeWidgetEntry: TimelineEntry {
  let date: Date
  let data: GreetingData
}


struct GreetingHomeWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tracking Profile:")
                .font(.caption)
            Text(entry.data.name ?? "")
                .font(.title).fontWeight(.bold)
            Color.clear
            .frame(width: 0.0, height: 8.0)
            Text("Total Words:")
                .font(.caption)
            Text(entry.data.wordsCount ?? "")
                .font(.headline).fontWeight(.bold)
        }
    .applyContainerBackground()
  }
}

struct GreetingHomeWidget: Widget {
  let kind: String = "GreetingHomeWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      GreetingHomeWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Greeting")
  }
}

extension View {
  @ViewBuilder
  func applyContainerBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(.fill.tertiary, for: .widget)
    } else if #available(iOSApplicationExtension 15.0, *) {
      self.background()
    } else {
      self
    }
  }
}

struct GreetingData {
  let name: String?
  let wordsCount: String?

  static let paramPrefix = "home_widget.Greeting"

  static func fromUserDefaults(_ defaults: UserDefaults?) -> GreetingData {
    return GreetingData(
      name: (defaults?.string(forKey: "\(paramPrefix).name") ?? "Baby"),
      wordsCount: (defaults?.string(forKey: "\(paramPrefix).wordsCount") ?? "0"),
    )
  }
}

