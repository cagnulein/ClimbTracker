import WidgetKit
import SwiftUI
import ClockKit

struct ProgressEntry: TimelineEntry {
    var date: Date
    let stairs: Double
    let steps: Double
    let avgFlightLastMonth: Double
    let avgStepsLastMonth: Double
}

// Fornisce i dati alla complication
class ProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(date: Date(), stairs: 10, steps: 2000, avgFlightLastMonth: 20, avgStepsLastMonth: 10000)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.climbTracker")
        let entry = ProgressEntry(date: Date(), stairs: sharedDefaults?.double(forKey: "stairs") ?? 0, steps: sharedDefaults?.double(forKey: "steps") ?? 0, avgFlightLastMonth: sharedDefaults?.double(forKey: "avgFlightLastMonth") ?? 0, avgStepsLastMonth: sharedDefaults?.double(forKey: "avgStepsLastMonth") ?? 0) // Dato di esempio per l'anteprima
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.climbTracker")
        let entry = ProgressEntry(date: Date(), stairs: sharedDefaults?.double(forKey: "stairs") ?? 0, steps: sharedDefaults?.double(forKey: "steps") ?? 0, avgFlightLastMonth: sharedDefaults?.double(forKey: "avgFlightLastMonth") ?? 0, avgStepsLastMonth: sharedDefaults?.double(forKey: "avgStepsLastMonth") ?? 0) // Dato di esempio per l'anteprima
        let entries: [ProgressEntry] = [entry] // Dati per la timeline
        let timeline = Timeline(entries: entries, policy: .atEnd) // Aggiorna alla fine del periodo della timeline
        completion(timeline)
    }
}

// Definisce l'interfaccia utente della complication
struct ProgressComplicationView: View {
    enum MeasurementUnit {
        case stairs, meters, feet, steps
    }
    
    var entry: ProgressEntry
    var unit: MeasurementUnit
    
    private func labelText() -> String {
        switch unit {
        case .stairs:
            return "Stairs"
        case .meters:
            return "Meters"
        case .feet:
            return "Feet"
        case .steps:
            return "Steps"
        }
    }
    
    private func currentValueText() -> String {
        switch unit {
        case .stairs:
            return "\(Int(entry.stairs))"
        case .meters:
            return "\(Int(entry.stairs * 3))"
        case .feet:
            return "\(Int(entry.stairs * 10))"
        case .steps:
            return "\(Int(entry.steps))"
        }
    }
    
    private func gaugeValue() -> Double {
        switch unit {
        case .stairs, .meters, .feet:
            return entry.stairs
        case .steps:
            return entry.steps
        }
    }
    
    private func maxValue() -> Double {
        switch unit {
        case .stairs, .meters, .feet:
            return max(entry.avgFlightLastMonth, entry.stairs)
        case .steps:
            return max(entry.avgStepsLastMonth, entry.steps)
        }
    }
    
    private func gaugeColor() -> Color {
        let fraction: Float
        switch unit {
        case .stairs, .meters, .feet:
            fraction = min(Float(entry.stairs) / Float(entry.avgFlightLastMonth), 1)
        case .steps:
            fraction = min(Float(entry.steps) / Float(entry.avgStepsLastMonth), 1)
        }
        
        let redComponent = CGFloat(1 - fraction)
        let greenComponent = CGFloat(fraction)
        return fraction == 1 ? .blue : Color(red: redComponent, green: greenComponent, blue: 0.0)
    }
    
    var body: some View {
        Gauge(value: gaugeValue(), in: 0...maxValue()) {
            Text(labelText())
        } currentValueLabel: {
            Text(currentValueText())
        }
        .gaugeStyle(CircularGaugeStyle(tint: gaugeColor()))
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}

// Configura e registra la complication
@main
struct ProgressComplication: WidgetBundle {
   var body: some Widget {
       stairs()
       steps()
       meters()
       feet()
   }
}

struct stairs: Widget {
    let kind: String = "Stairs"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressProvider()) { entry in
            ProgressComplicationView(entry: entry, unit: .stairs)
        }
        .supportedFamilies([.accessoryCircular]) // Specifica le famiglie di complication supportate
        .configurationDisplayName("Stairs")
    }
}

struct meters: Widget {
    let kind: String = "Meters"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressProvider()) { entry in
            ProgressComplicationView(entry: entry, unit: .meters)
        }
        .supportedFamilies([.accessoryCircular]) // Specifica le famiglie di complication supportate
        .configurationDisplayName("Meters")
    }
}

struct feet: Widget {
    let kind: String = "Feet"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressProvider()) { entry in
            ProgressComplicationView(entry: entry, unit: .feet)
        }
        .supportedFamilies([.accessoryCircular]) // Specifica le famiglie di complication supportate
        .configurationDisplayName("Feet")
    }
}

struct steps: Widget {
    let kind: String = "Steps"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressProvider()) { entry in
            ProgressComplicationView(entry: entry, unit: .steps)
        }
        .supportedFamilies([.accessoryCircular]) // Specifica le famiglie di complication supportate
        .configurationDisplayName("Steps")
    }
}


#Preview {
    ProgressComplicationView(entry: ProgressEntry.init(date: Date(), stairs: 6, steps: 2000, avgFlightLastMonth: 10, avgStepsLastMonth: 10000), unit: .meters)
}
