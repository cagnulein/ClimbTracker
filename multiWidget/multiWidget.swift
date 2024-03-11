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
    var entry: ProgressProvider.Entry

    var body: some View {
        let fraction = (Float(entry.stairs) / Float(entry.avgFlightLastMonth) > 1 ? 1 : Float(entry.stairs) / Float(entry.avgFlightLastMonth))
        let redComponent = CGFloat(1 - fraction) // Diminuisce con l'aumentare di f
        let greenComponent = CGFloat(fraction) // Aumenta con l'aumentare di f
        var color :Color = Color(red: redComponent, green: greenComponent, blue: 0.0)
        if(fraction == 1) {
            color = .blue
        }
        Gauge(value: entry.stairs, in: 0...(entry.avgFlightLastMonth > entry.stairs ? entry.avgFlightLastMonth : entry.stairs)) { // Utilizza un range da 0 a 1 per il progresso
            Text("Stairs")
        } currentValueLabel: {
            Text("\(Int(entry.stairs))") // Mostra il progresso come percentuale
        }
        .gaugeStyle(CircularGaugeStyle(tint: color)) // Stile della gauge
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}

struct ProgressComplicationViewSteps: View {
    var entry: ProgressProvider.Entry

    var body: some View {
        let fraction = (Float(entry.steps) / Float(entry.avgStepsLastMonth) > 1 ? 1 : Float(entry.steps) / Float(entry.avgStepsLastMonth))
        let redComponent = CGFloat(1 - fraction) // Diminuisce con l'aumentare di f
        let greenComponent = CGFloat(fraction) // Aumenta con l'aumentare di f
        let color :Color = Color(red: redComponent, green: greenComponent, blue: 0.0)
        if(fraction == 1) {
            color = .blue
        }
        Gauge(value: entry.steps, in: 0...(entry.avgStepsLastMonth > entry.steps ? entry.avgStepsLastMonth : entry.steps)) { // Utilizza un range da 0 a 1 per il progresso
            Text("Steps")
        } currentValueLabel: {
            Text("\(Int(entry.steps))") // Mostra il progresso come percentuale
        }
        .gaugeStyle(CircularGaugeStyle(tint: color)) // Stile della gauge
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
   }
}

struct stairs: Widget {
    let kind: String = "Stairs"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressProvider()) { entry in
            ProgressComplicationView(entry: entry)
        }
        .supportedFamilies([.accessoryCircular]) // Specifica le famiglie di complication supportate
        .configurationDisplayName("Stairs")
        .description("Mostra il progresso in una gauge circolare.")
    }
}

struct steps: Widget {
    let kind: String = "Steps"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressProvider()) { entry in
            ProgressComplicationViewSteps(entry: entry)
        }
        .supportedFamilies([.accessoryCircular]) // Specifica le famiglie di complication supportate
        .configurationDisplayName("Steps")
        .description("Mostra il progresso in una gauge circolare.")
    }
}


#Preview {
    ProgressComplicationView(entry: ProgressEntry.init(date: Date(), stairs: 6, steps: 2000, avgFlightLastMonth: 10, avgStepsLastMonth: 10000))
}
