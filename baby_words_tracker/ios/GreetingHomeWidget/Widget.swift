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

  @Environment(\.colorScheme) var colorScheme

  var body: some View {
        VStack(alignment: .leading) {
            Text(entry.data.name ?? "")
                .font(.title).fontWeight(.bold)
            HStack(alignment: .center) {
                Text(entry.data.wordsCount ?? "")
                    .font(.headline).fontWeight(.bold)
                Text(" words")
                    .font(.headline).fontWeight(.bold)
            }
        }
    .applyContainerBackground((colorScheme == .dark ? Color(red: 0.19607843137254902, green: 0.1568627450980392, blue: 0.15294117647058825, opacity: 1.0) : Color(red: 0.9882352941176471, green: 0.9176470588235294, blue: 0.9098039215686274, opacity: 1.0)))
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
  func applyContainerBackground<T: View>(_ backgroundView: T) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) { backgroundView }
    } else {
      self.background(backgroundView)
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

