//
//  ContentView.swift
//  ClimbTracker Watch App
//
//  Created by Roberto Viola on 25/02/24.
//

import SwiftUI
import Combine
import ClockKit
import WatchKit
import Foundation

struct ContentView: View {    
    
    @State private var flights = 0.0
    @State private var steps = 0.0

    @State private var avgflights = 0.0
    @State private var avgsteps = 0.0
    
    // Dati di esempio - sostituisci con i tuoi dati reali
    @State private var flightsData: [Int: Double] = [:]
    @State private var stepsData: [Int: Double] = [:]
    @State private var avgflightsData: [Int: Double] = [:]
    @State private var avgstepsData: [Int: Double] = [:]
    /*
    @State private var flights = 13.0
    @State private var steps = 303.0

    @State private var avgflights = 15.0
    @State private var avgsteps = 528.0

    // Dati di esempio - sostituisci con i tuoi dati reali
    @State private var flightsData: [Int: Double] = [9: 3.0, 10: 5.0, 11: 8.0, 12: 11]
    @State private var stepsData: [Int: Double] = [9: 500.0, 10: 520.0, 11: 540.0, 12: 600]
    @State private var avgflightsData: [Int: Double] = [1: 5.0, 2: 6.0, 3: 7.0, 4: 5]
    @State private var avgstepsData: [Int: Double] = [1: 250.0, 2: 260.0, 3: 270.0, 4: 400]*/

    
    @State private var cancellable: AnyCancellable?
    
    var inPreview: Bool
       
       var maxFlights: Double {
           flightsData.values.max() ?? 0
       }
       
       var maxSteps: Double {
           stepsData.values.max() ?? 0
       }
       
    @State private var last7DaysSteps: [Double] = []
    @State private var last7DaysFlights: [Double] = []


    private func calculateTrend(for last7DaysData: [Double], comparedTo previousData: Double) -> String {
        let last7DaysAverage = last7DaysData.reduce(0, +) / Double(last7DaysData.count)
        
        let difference = last7DaysAverage / previousData
        
        print("difference \(difference) \(last7DaysAverage)")
        if difference >= 1.1 {
            if difference > 1.2 { // Aumento significativo
                return "increasing_significantly"
            } else { // Aumento lieve
                return "increasing_slightly"
            }
        } else if difference <= 0.9 {
            if difference > 1.2 { // Diminuzione significativa
                return "decreasing_significantly"
            } else { // Diminuzione lieve
                return "decreasing_slightly"
            }
        }
        return "stable"
    }

    private func avg30DaysSteps() -> Int {
        let defaults = UserDefaults.standard
        var scores: [String: Int] = [:]
        if let data = defaults.data(forKey: "dailySteps"),
           let savedScores = try? PropertyListDecoder().decode([String: Int].self, from: data) {
            scores = savedScores
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let calendar = Calendar.current
        let today = Date()
        guard let oneMonthBack = calendar.date(byAdding: .month, value: -1, to: today) else { return 0 }

        let filteredScores = scores.filter {
            guard let date = dateFormatter.date(from: $0.key) else { return false }
            return date >= oneMonthBack
        }

        let avg = filteredScores.values.reduce(0, +) / filteredScores.count
        print("avgsteps30days \(Double(avg))")
        let sharedDefaults = UserDefaults(suiteName: "group.climbTracker")
        sharedDefaults?.set(avg, forKey: "avgStepsLastMonth")
        return avg
    }
    
    private func avg30DaysFlights() -> Int {
        let defaults = UserDefaults.standard
        var scores: [String: Int] = [:]
        if let data = defaults.data(forKey: "dailyFlights"),
           let savedScores = try? PropertyListDecoder().decode([String: Int].self, from: data) {
            scores = savedScores
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let calendar = Calendar.current
        let today = Date()
        guard let oneMonthBack = calendar.date(byAdding: .month, value: -1, to: today) else { return 0 }

        let filteredScores = scores.filter {
            guard let date = dateFormatter.date(from: $0.key) else { return false }
            return date >= oneMonthBack
        }

        let avg = filteredScores.values.reduce(0, +) / filteredScores.count
        print("avgflights30days \(Double(avg))")
        let sharedDefaults = UserDefaults(suiteName: "group.climbTracker")
        sharedDefaults?.set(avg, forKey: "avgFlightLastMonth")
        print("\(sharedDefaults?.double(forKey: "avgFlightLastMonth"))")

        printUserDefaultsData(forKey: "dailyFlights")
        printUserDefaultsData(forKey: "dailySteps")

        return avg
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                TabView {                    
                        VStack {                            
                            Text("7-Day Trend").font(.headline)
                            Spacer()
                            if(last7DaysSteps.count >= 7) {    
                                // Trend per i Steps
                                let trendSteps = calculateTrend(for: last7DaysSteps, comparedTo: Double(avg30DaysSteps()))
                                // Trend per i Flights
                                let trendFlights = calculateTrend(for: last7DaysFlights, comparedTo: Double(avg30DaysFlights()))

                                // Feedback per i Steps
                                switch trendSteps {
                                case "increasing_significantly":
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill").foregroundColor(.green)   
                                    Text("Your step count has greatly increased, excellent job!").foregroundColor(.green)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.leading)
                                }
                                case "increasing_slightly":
                                HStack {
                                    Image(systemName: "arrow.up.circle").foregroundColor(.green)
                                    Text("Your steps are slightly up. Keep it up!").foregroundColor(.green)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.leading)
                                }
                                case "decreasing_significantly":
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill").foregroundColor(.red)
                                    Text("Your step count has significantly decreased, try to move more!").foregroundColor(.red)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.leading)
                                }
                                case "decreasing_slightly":
                                HStack {
                                    Image(systemName: "arrow.down.circle").foregroundColor(.red)
                                    Text("You've slowed down a bit in steps. Every step counts!").foregroundColor(.red)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.leading)
                                }
                                default:
                                HStack {
                                    Image(systemName: "equal.circle.fill").foregroundColor(.blue)
                                    Text("You're keeping a consistent pace in steps, well done!").foregroundColor(.blue)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.leading)
                                }
                                }

                                Spacer().frame(height: 20) // Aggiunge spazio tra i feedback dei steps e dei flights

                                // Feedback per i Flights
                                switch trendFlights {
                                case "increasing_significantly":
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill").foregroundColor(.green)
                                    Text("You've climbed significantly more stairs, amazing effort!").foregroundColor(.green)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.leading)
                                }
                                case "increasing_slightly":
                                HStack {
                                    Image(systemName: "arrow.up.circle").foregroundColor(.green)
                                    Text("A slight increase in stairs climbed. Good job!").foregroundColor(.green)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.leading)
                                }
                                case "decreasing_significantly":
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill").foregroundColor(.red)
                                    Text("There's a significant drop in your stairs climbing. Let's aim higher!").foregroundColor(.red)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.leading)
                                }
                                case "decreasing_slightly":
                                    HStack {                                
                                        Image(systemName: "arrow.down.circle").foregroundColor(.red)
                                        Text("You've climbed fewer stairs lately. Every floor counts!").foregroundColor(.red)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.leading)
                                    }
                                default:
                                    HStack {
                                        Image(systemName: "equal.circle.fill").foregroundColor(.blue)
                                        Text("Your pace in climbing stairs is consistent, nicely done!").foregroundColor(.blue)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            } else {
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill").foregroundColor(.green)                                
                                    Text("Use the app for at least 7 days and you will see your trends here!").foregroundColor(.blue)
                                                                                .fixedSize(horizontal: false, vertical: true)
                                                                                .lineLimit(nil)
                                                                                .frame(maxWidth: .infinity, alignment: .center)
                                                                                .multilineTextAlignment(.leading)                                
                                }
                            }
                        }
                        .padding().onAppear {
                            fetchAllData()
                        }                
    
                        VStack{
                            VStack {
                                Text("Today")
                                Text("Stairs: \(flights, specifier: "%.0f")").font(.caption2)
                                Text("Steps: \(steps, specifier: "%.0f")").font(.caption2)
                                
                                // La tua ScrollView va qui
                                
                            }.padding(.top, 20)
                                .onAppear {
                                    // Chiedi l'autorizzazione a HealthKit e carica i dati iniziali
                                    HealthKitManager.shared.requestAuthorization { success, _ in
                                        if success {
                                            self.fetchAllData()
                                        }
                                    }
                                    
                                    // Effettua la sottoscrizione quando la vista appare
                                    cancellable = NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)
                                        .sink { _ in
                                            self.fetchAllData()
                                        }
                                    
                                }
                                .onDisappear {
                                    // Cancella la sottoscrizione quando la vista scompare per evitare riferimenti circolari
                                    self.cancellable?.cancel()
                                }
                            
                            ScrollView(.horizontal) {
                                HStack(alignment: .bottom, spacing: 4) {
                                    // Calcola il range dinamico basato sui dati disponibili
                                    let uniqueHours = Set(Array(flightsData.keys) + Array(stepsData.keys))
                                    // Filtra per includere solo le ore con attività
                                    let filteredHours = uniqueHours.filter { hour in
                                        let hasFlights = flightsData[hour] ?? 0 > 0
                                        let hasSteps = stepsData[hour] ?? 0 > 50
                                        return hasFlights || hasSteps
                                    }
                                    
                                    let sortedHours = filteredHours.sorted()
                                    
                                    if let firstHour = sortedHours.first, let lastHour = sortedHours.last {
                                        ForEach(firstHour...lastHour, id: \.self) { hour in
                                            VStack(spacing: 0) {
                                                Spacer()
                                                HStack(alignment: .bottom, spacing: 4) {
                                                    // Gestisci la visualizzazione dei flights
                                                    if let flightValue = flightsData[hour], flightValue > 0 {
                                                        VStack {
                                                            Text("\(Int(flightValue))")
                                                                .font(.caption2)
                                                            Rectangle()
                                                                .fill(Color.blue)
                                                                .frame(width: 10, height: calculateBarHeight(for: flightValue, isFlight: true)).cornerRadius(5)
                                                        }.transition(.opacity).animation(.easeInOut(duration: 0.5), value: flightValue)
                                                    } else if flightsData.keys.contains(hour) || (flightsData.keys.contains { $0 < hour } && flightsData.keys.contains { $0 > hour }) {
                                                        Spacer().frame(width: 10) // Mostra spazio vuoto per ore senza dati in mezzo
                                                    }
                                                    
                                                    // Gestisci la visualizzazione dei steps
                                                    if let stepValue = stepsData[hour], stepValue > 0 {
                                                        VStack {
                                                            Text("\(Int(stepValue))")
                                                                .font(.caption2)
                                                            Rectangle()
                                                                .fill(Color.green)
                                                                .frame(width: 10, height: calculateBarHeight(for: stepValue, isFlight: false)).cornerRadius(5)
                                                        }.transition(.opacity).animation(.easeInOut(duration: 0.5), value: stepValue)
                                                    } else if stepsData.keys.contains(hour) || (stepsData.keys.contains { $0 < hour } && stepsData.keys.contains { $0 > hour }) {
                                                        Spacer().frame(width: 10) // Mostra spazio vuoto per ore senza dati in mezzo
                                                    }
                                                }
                                                Text("\(hour):00")
                                                    .font(.caption2)
                                            }
                                            .frame(height: 150)
                                        }
                                    }
                                }
                            }
                        }.onAppear {
                            if(inPreview == false) {
                                HealthKitManager.shared.fetchFlightsClimbedTodayByHour { flightsByHour, _ in
                                    self.flightsData = flightsByHour ?? [:]
                                    self.flights = flightsData.values.reduce(0, +)
                                }
                                
                                HealthKitManager.shared.fetchStepsTodayByHour { stepsByHour, _ in
                                    self.stepsData = stepsByHour ?? [:]
                                    self.steps = stepsData.values.reduce(0, +)
                                }
                            }
                        }
                        .padding([.bottom], 35).padding([.leading, .trailing], 15)
                        VStack{
                            VStack {
                                Text("Last 7 days")
                                Text("AVG Stairs: \(avgflights, specifier: "%.0f")").font(.caption2)
                                Text("AVG Steps: \(avgsteps, specifier: "%.0f")").font(.caption2)
                                
                                // La tua ScrollView va qui
                                
                            }.padding(.top, 20)
                                .onAppear {
                                    // Chiedi l'autorizzazione a HealthKit e carica i dati iniziali
                                    HealthKitManager.shared.requestAuthorization { success, _ in
                                        if success {
                                            self.fetchAllData()
                                        }
                                    }
                                    
                                    // Effettua la sottoscrizione quando la vista appare
                                    cancellable = NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)
                                        .sink { _ in
                                            self.fetchAllData()
                                        }
                                    
                                }
                                .onDisappear {
                                    // Cancella la sottoscrizione quando la vista scompare per evitare riferimenti circolari
                                    self.cancellable?.cancel()
                                }
                            
                            ScrollView(.horizontal) {
                                HStack(alignment: .bottom, spacing: 4) {
                                    // Calcola il range dinamico basato sui dati disponibili
                                    let uniqueHours = Set(Array(avgflightsData.keys) + Array(avgstepsData.keys))
                                    // Filtra per includere solo le ore con attività
                                    let filteredHours = uniqueHours.filter { hour in
                                        let hasFlights = avgflightsData[hour] ?? 0 > 0
                                        let hasSteps = avgstepsData[hour] ?? 0 > 50
                                        return hasFlights || hasSteps
                                    }
                                    
                                    let sortedHours = filteredHours.sorted()
                                    
                                    if let firstHour = sortedHours.first, let lastHour = sortedHours.last {
                                        ForEach(firstHour...lastHour, id: \.self) { hour in
                                            VStack(spacing: 0) {
                                                Spacer()
                                                HStack(alignment: .bottom, spacing: 4) {
                                                    // Gestisci la visualizzazione dei avgflights
                                                    if let flightValue = avgflightsData[hour], flightValue > 0 {
                                                        VStack {
                                                            Text("\(Int(flightValue))")
                                                                .font(.caption2)
                                                            Rectangle()
                                                                .fill(Color.blue)
                                                                .frame(width: 10, height: calculateBarHeightAVG(for: flightValue, isFlight: true)).cornerRadius(5)
                                                        }
                                                    } else if avgflightsData.keys.contains(hour) || (avgflightsData.keys.contains { $0 < hour } && avgflightsData.keys.contains { $0 > hour }) {
                                                        Spacer().frame(width: 10) // Mostra spazio vuoto per ore senza dati in mezzo
                                                    }
                                                    
                                                    // Gestisci la visualizzazione dei avgsteps
                                                    if let stepValue = avgstepsData[hour], stepValue > 0 {
                                                        VStack {
                                                            Text("\(Int(stepValue))")
                                                                .font(.caption2)
                                                            Rectangle()
                                                                .fill(Color.green)
                                                                .frame(width: 10, height: calculateBarHeightAVG(for: stepValue, isFlight: false)).cornerRadius(5)
                                                        }
                                                    } else if avgstepsData.keys.contains(hour) || (avgstepsData.keys.contains { $0 < hour } && avgstepsData.keys.contains { $0 > hour }) {
                                                        Spacer().frame(width: 10) // Mostra spazio vuoto per ore senza dati in mezzo
                                                    }
                                                }
                                                Text("\(hour)")
                                                    .font(.caption2)
                                            }
                                            .frame(height: 150)
                                        }
                                    }
                                
                            }
                        }.onAppear {                            
                            if(inPreview == false) {
                                HealthKitManager.shared.fetchFlightsClimbedThisMonthByDay { avgflightsByDay, _ in
                                    self.avgflightsData = avgflightsByDay ?? [:]
                                    if(Double(avgflightsData.values.count) > 0) {
                                        self.avgflights = avgflightsData.values.reduce(0, +) / Double(avgflightsData.values.count)
                                    } else {
                                        self.avgflights = 0
                                    }
                                }
                                
                                HealthKitManager.shared.fetchStepsThisMonthByDay { avgstepsByDay, _ in
                                    self.avgstepsData = avgstepsByDay ?? [:]
                                    if(avgstepsData.values.count > 0) {
                                        self.avgsteps = avgstepsData.values.reduce(0, +) / Double(avgstepsData.values.count)
                                    } else {
                                        self.avgsteps = 0
                                    }
                                }
                            }
                        }
                        .padding([.bottom], 35).padding([.leading, .trailing], 15)
                    }
                    VStack{
                        VStack {
                            Text("Your target Stairs level is based on your monthly average of:")
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil) // Assicurati che il limite di linee sia impostato su nil per permettere un numero illimitato di righe
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                            Spacer()
                            let avgflights30days = Double(avg30DaysFlights())
                            Text("\(avgflights30days, specifier: "%.0f")").font(.title).foregroundColor(colorProgressBar(fraction: self.flights / avgflights30days))
                            Text("or \(avgflights30days * 3, specifier: "%.0f") meters").font(.footnote)
                            Text("or \(avgflights30days * 10, specifier: "%.0f") feet").font(.footnote)
                            Spacer()
                            ProgressView(value: self.flights, total: avgflights30days ).progressViewStyle(.linear)
                            Text("Current: \(Int(self.flights))").font(.footnote)
                        }.padding(.top, 20)
                    }
                    .padding(.bottom, 25)

                    VStack{
                        VStack {
                            Text("Your target Steps level is based on your monthly average of:")
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil) // Assicurati che il limite di linee sia impostato su nil per permettere un numero illimitato di righe
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                            Spacer()
                            let avgsteps30days = Double(avg30DaysSteps())
                            Text("\(avgsteps30days, specifier: "%.0f")").font(.title).foregroundColor(colorProgressBar(fraction: self.steps / avgsteps30days))
                            Spacer()
                            ProgressView(value: self.steps, total: avgsteps30days ).progressViewStyle(.linear)
                            Text("Current: \(Int(self.steps))").font(.footnote)
                               
                        }.padding(.top, 20)
                    }
                    .padding(.bottom, 25)                        

                }.tabViewStyle(PageTabViewStyle())
            }
        }
    }
    
    private func fetchAllData() {
       HealthKitManager.shared.fetchFlightsClimbedTodayByHour { flightsByHour, _ in
           self.flightsData = flightsByHour ?? [:]
           self.flights = flightsData.values.reduce(0, +)
       }
       
       HealthKitManager.shared.fetchStepsTodayByHour { stepsByHour, _ in
           self.stepsData = stepsByHour ?? [:]
           self.steps = stepsData.values.reduce(0, +)
       }

        HealthKitManager.shared.fetchAverageQuantityLastMonth(for: .flightsClimbed) { data, _ in
            self.avgflights = data ?? 0
        }
        
        HealthKitManager.shared.fetchAverageQuantityLastMonth(for: .stepCount) { data, _ in
            self.avgsteps = data ?? 0
        }
        
        HealthKitManager.shared.fetchFlightsClimbedThisMonthByDay { avgflightsByDay, _ in
            self.avgflightsData = avgflightsByDay ?? [:]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let calendar = Calendar.current
            let today = Date()
            let components = calendar.dateComponents([.year, .month], from: today)
            let year = components.year!
            let month = components.month!
            
            var scores: [String: Int] = [:]
            
            for (index, flightData) in avgflightsData.enumerated() {
                let day = flightData.key
                let dateStr = String(format: "%04d-%02d-%02d", year, month, day)
                
                scores[dateStr] = Int(flightData.value)
                print("dailyFlights \(dateStr) \(scores[dateStr])")
            }
            
            // Salva il dizionario scores
            if let encodedData = try? PropertyListEncoder().encode(scores) {
                UserDefaults.standard.set(encodedData, forKey: "dailyFlights")
            }
        }

        HealthKitManager.shared.fetchStepsThisMonthByDay { avgstepsByDay, _ in
            self.avgstepsData = avgstepsByDay ?? [:]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let calendar = Calendar.current
            let today = Date()
            let components = calendar.dateComponents([.year, .month], from: today)
            let year = components.year!
            let month = components.month!
            
            var scores: [String: Int] = [:]
            
            for (index, flightData) in avgstepsData.enumerated() {
                let day = flightData.key
                let dateStr = String(format: "%04d-%02d-%02d", year, month, day)
                
                scores[dateStr] = Int(flightData.value)
                print("dailySteps \(dateStr) \(scores[dateStr])")
            }
            
            // Salva il dizionario scores
            if let encodedData = try? PropertyListEncoder().encode(scores) {
                UserDefaults.standard.set(encodedData, forKey: "dailySteps")
            }
        }

        HealthKitManager.shared.fetchLast7DaysSteps { [self] stepsData, _ in
            DispatchQueue.main.async {
                self.last7DaysSteps = stepsData ?? []
            }
        }

        HealthKitManager.shared.fetchLast7DaysFlights { [self] flightsData, _ in
            DispatchQueue.main.async {
                self.last7DaysFlights = flightsData ?? []
            }
        }        
    }
    
    private func colorProgressBar(fraction: Double) -> Color {
        let redComponent = CGFloat(1 - fraction)
        let greenComponent = CGFloat(fraction)
        return fraction >= 1 ? .blue : Color(red: redComponent, green: greenComponent, blue: 0.0)
    }
    
    private func calculateBarHeight(for value: Double, isFlight: Bool) -> CGFloat {
        // Calcola l'altezza della barra in base ai massimi valori di flights o steps
        let maxValue = isFlight ? (flightsData.values.max() ?? 0) : (stepsData.values.max() ?? 0)
        return CGFloat(value / (maxValue == 0 ? 1 : maxValue)) * 100
    }

    private func calculateBarHeightAVG(for value: Double, isFlight: Bool) -> CGFloat {
        // Calcola l'altezza della barra in base ai massimi valori di flights o steps
        let maxValue = isFlight ? (avgflightsData.values.max() ?? 0) : (avgstepsData.values.max() ?? 0)
        return CGFloat(value / (maxValue == 0 ? 1 : maxValue)) * 100
    }

    private func printUserDefaultsData(forKey key: String) {
        let defaults = UserDefaults.standard
        if let savedData = defaults.data(forKey: key),
        let decodedData = try? PropertyListDecoder().decode([String: Int].self, from: savedData) {
            for (date, value) in decodedData.sorted(by: { $0.key < $1.key }) {
                print("\"\(date)\": \(value),")
            }
        }
    }

}


#Preview {
    ContentView(inPreview: true)
}
