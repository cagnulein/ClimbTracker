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
    @State private var flights = 0.0 // Usare private per migliorare l'incapsulamento
    @State private var steps = 0.0 // Usare private per migliorare l'incapsulamento

    // Dati di esempio - sostituisci con i tuoi dati reali
    @State private var flightsData: [Int: Double] = [:]
    @State private var stepsData: [Int: Double] = [:]
    @State private var cancellable: AnyCancellable?
       
       var maxFlights: Double {
           flightsData.values.max() ?? 0
       }
       
       var maxSteps: Double {
           stepsData.values.max() ?? 0
       }
       
    
    var body: some View {
        VStack {
            VStack {
                        Text("Today's Stairs: \(flights, specifier: "%.0f")")
                        Text("Today's Steps: \(steps, specifier: "%.0f")")
                        
                        // La tua ScrollView va qui
                        
                    }.padding(.top, 20)
                    .onAppear {
                        // Effettua la sottoscrizione quando la vista appare
                        cancellable = NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)
                            .sink { _ in
                                self.fetchAllData()
                            }
                        
                        // Chiedi l'autorizzazione a HealthKit e carica i dati iniziali
                        HealthKitManager.shared.requestAuthorization { success, _ in
                            if success {
                                self.fetchAllData()
                            }
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
                                                       .frame(width: 10, height: calculateBarHeight(for: flightValue, isFlight: true))
                                               }
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
                                                       .frame(width: 10, height: calculateBarHeight(for: stepValue, isFlight: false))
                                               }
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
                        HealthKitManager.shared.fetchFlightsClimbedTodayByHour { flightsByHour, _ in
                            self.flightsData = flightsByHour ?? [:]
                            self.flights = flightsData.values.reduce(0, +)
                        }
                        
                        HealthKitManager.shared.fetchStepsTodayByHour { stepsByHour, _ in
                            self.stepsData = stepsByHour ?? [:]
                            self.steps = stepsData.values.reduce(0, +)
                        }
                    }
               .padding(.bottom, 15)
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
    }
    
    private func calculateBarHeight(for value: Double, isFlight: Bool) -> CGFloat {
        // Calcola l'altezza della barra in base ai massimi valori di flights o steps
        let maxValue = isFlight ? (flightsData.values.max() ?? 0) : (stepsData.values.max() ?? 0)
        return CGFloat(value / (maxValue == 0 ? 1 : maxValue)) * 100
    }
}


#Preview {
    ContentView()
}
