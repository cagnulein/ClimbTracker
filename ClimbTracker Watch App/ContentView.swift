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
    
    /*@State private var flights = 13.0
    @State private var steps = 3023.0

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
       
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                TabView {
                    
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
                                Text("Current Month")
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
                            Text("Your target Stairs level in the widget is based on your monthly average of:")
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil) // Assicurati che il limite di linee sia impostato su nil per permettere un numero illimitato di righe
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                            Spacer()
                            Text("\(avgflights, specifier: "%.0f")").font(.title)
                        }.padding(.top, 20)
                    }
                    .padding(.bottom, 25)

                    VStack{
                        VStack {
                            Text("Your target Steps level in the widget is based on your monthly average of:")
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil) // Assicurati che il limite di linee sia impostato su nil per permettere un numero illimitato di righe
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                            Spacer()
                            Text("\(avgsteps, specifier: "%.0f")").font(.title)
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
        }

        HealthKitManager.shared.fetchStepsThisMonthByDay { avgstepsByDay, _ in
            self.avgstepsData = avgstepsByDay ?? [:]
        }
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
}


#Preview {
    ContentView(inPreview: true)
}
