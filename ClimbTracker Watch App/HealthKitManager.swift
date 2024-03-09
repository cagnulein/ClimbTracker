import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    public var avgFlightLastMonth = 0.0
    public var avgStepsLastMonth = 0.0
    private init() {
        print("HealthKitManager init")
    } // Privato per Singleton

    let healthStore = HKHealthStore()

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }

        guard let flightsClimbed = HKObjectType.quantityType(forIdentifier: .flightsClimbed) else {
            completion(false, nil)
            return
        }
        
        guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(false, nil)
            return
        }

        healthStore.requestAuthorization(toShare: [], read: [flightsClimbed, steps]) { success, error in
            completion(success, error)
            self.fetchMaxFlightsClimbedLastMonth {
                f, error in
                print("avgFlightLastMonth \(f ?? 0)")
                self.avgFlightLastMonth = f ?? 0
            }
            self.fetchMaxStepsClimbedLastMonth {
                f, error in
                print("avgStepsLastMonth \(f ?? 0)")
                self.avgStepsLastMonth = f ?? 0
            }

        }
    }

    func fetchStepsTakenToday(completion: @escaping (Double?, Error?) -> Void) {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, nil)
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, error)
                return
            }

            let stepsTaken = sum.doubleValue(for: HKUnit.count())
            completion(stepsTaken, nil)
        }

        healthStore.execute(query)
    }

    
    func fetchFlightsClimbedToday(completion: @escaping (Double?, Error?) -> Void) {
        guard let flightsClimbedType = HKObjectType.quantityType(forIdentifier: .flightsClimbed) else {
            completion(nil, nil)
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: flightsClimbedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, error)
                return
            }

            let flightsClimbed = sum.doubleValue(for: HKUnit.count())
            completion(flightsClimbed, nil)
        }

        healthStore.execute(query)
    }

    func fetchMaxFlightsClimbedLastMonth(completion: @escaping (Double?, Error?) -> Void) {
        guard let flightsClimbedType = HKObjectType.quantityType(forIdentifier: .flightsClimbed) else {
            print("Nessun tipo di dato trovato per i flightsClimbed")
            completion(nil, nil) // Nessun tipo di dato trovato per i flightsClimbed
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Ottieni la data di inizio dell'ultimo mese
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now),
              let startOfLastMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: oneMonthAgo)) else {
            completion(nil, nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfLastMonth, end: Date(), options: .strictStartDate)
        
        // Crea l'intervallo di date per la query
        var interval = DateComponents()
        interval.day = 1
        
        // Crea la HKStatisticsCollectionQuery
        let query = HKStatisticsCollectionQuery(quantityType: flightsClimbedType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: startOfLastMonth, intervalComponents: interval)
        
        query.initialResultsHandler = { query, results, error in
            guard let statsCollection = results else {
                completion(nil, error) // Errore o nessun dato trovato
                return
            }
            
            // Calcola la media dei voli saliti
            var totalFlights: Double = 0
            var daysCounted: Double = 0
            statsCollection.enumerateStatistics(from: startOfLastMonth, to: Date()) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    let flights = sum.doubleValue(for: HKUnit.count())
                    totalFlights += flights
                    if flights > 0 {
                        daysCounted += 1
                    }
                }
            }

            let averageFlights = daysCounted > 0 ? totalFlights / daysCounted : 0
            
            completion(averageFlights, nil)
        }
        
        HKHealthStore().execute(query)
    }
    
    func fetchMaxStepsClimbedLastMonth(completion: @escaping (Double?, Error?) -> Void) {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, nil) // Nessun tipo di dato trovato per i flightsClimbed
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Ottieni la data di inizio dell'ultimo mese
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now),
              let startOfLastMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: oneMonthAgo)) else {
            completion(nil, nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfLastMonth, end: Date(), options: .strictStartDate)
        
        // Crea l'intervallo di date per la query
        var interval = DateComponents()
        interval.day = 1
        
        // Crea la HKStatisticsCollectionQuery
        let query = HKStatisticsCollectionQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: startOfLastMonth, intervalComponents: interval)
        
        query.initialResultsHandler = { query, results, error in
            guard let statsCollection = results else {
                completion(nil, error) // Errore o nessun dato trovato
                return
            }
            
            // Calcola la media dei voli saliti
            var totalFlights: Double = 0
            var daysCounted: Double = 0
            statsCollection.enumerateStatistics(from: startOfLastMonth, to: Date()) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    let flights = sum.doubleValue(for: HKUnit.count())
                    totalFlights += flights
                    if flights > 0 {
                        daysCounted += 1
                    }
                }
            }

            let averageFlights = daysCounted > 0 ? totalFlights / daysCounted : 0
            
            completion(averageFlights, nil)
        }
        
        HKHealthStore().execute(query)
    }

    func fetchFlightsClimbedThisMonthByDay(completion: @escaping ([Int: Double]?, Error?) -> Void) {
        fetchDataByDay(forIdentifier: .flightsClimbed, completion: completion)
    }
    
    // Funzione per recuperare i passi fatti oggi per ogni ora
    func fetchStepsThisMonthByDay(completion: @escaping ([Int: Double]?, Error?) -> Void) {
        fetchDataByDay(forIdentifier: .stepCount, completion: completion)
    }
    
    func fetchFlightsClimbedTodayByHour(completion: @escaping ([Int: Double]?, Error?) -> Void) {
        fetchDataByHour(forIdentifier: .flightsClimbed, completion: completion)
    }
    
    // Funzione per recuperare i passi fatti oggi per ogni ora
    func fetchStepsTodayByHour(completion: @escaping ([Int: Double]?, Error?) -> Void) {
        fetchDataByHour(forIdentifier: .stepCount, completion: completion)
    }
    
    // Funzione di supporto per eseguire le query HealthKit
    private func fetchDataByHour(forIdentifier identifier: HKQuantityTypeIdentifier, completion: @escaping ([Int: Double]?, Error?) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil, nil) // Tipo di dato non trovato
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        var interval = DateComponents()
        interval.hour = 1
        
        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: startOfDay, intervalComponents: interval)
        
        query.initialResultsHandler = { query, results, error in
            guard let results = results else {
                completion(nil, error)
                return
            }
            
            var data: [Int: Double] = [:]
            
            results.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in
                let hour = Calendar.current.component(.hour, from: statistics.startDate)
                let value = statistics.sumQuantity()?.doubleValue(for: identifier == .flightsClimbed ? HKUnit.count() : HKUnit.count()) ?? 0
                data[hour] = value
            }
            
            completion(data, nil)
        }
        
        healthStore.execute(query)
    }

    // Funzione di supporto per eseguire le query HealthKit
    private func fetchDataByDay(forIdentifier identifier: HKQuantityTypeIdentifier, completion: @escaping ([Int: Double]?, Error?) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil, nil) // Tipo di dato non trovato
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfMonth, end: endOfMonth, options: .strictStartDate)

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: startOfMonth, intervalComponents: interval)
        
        query.initialResultsHandler = { query, results, error in
            guard let results = results else {
                completion(nil, error)
                return
            }
            
            var data: [Int: Double] = [:]
            
            results.enumerateStatistics(from: startOfMonth, to: endOfMonth) { statistics, _ in
                let hour = Calendar.current.component(.day, from: statistics.startDate)
                let value = statistics.sumQuantity()?.doubleValue(for: identifier == .flightsClimbed ? HKUnit.count() : HKUnit.count()) ?? 0
                data[hour] = value
            }
            
            completion(data, nil)
        }
        
        healthStore.execute(query)
    }
    
}
