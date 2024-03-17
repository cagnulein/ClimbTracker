import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    public var avgFlightLastMonth = 0.0
    public var avgStepsLastMonth = 0.0
    public var lastFligth = 0.0
    public var lastStep = 0.0
    private init() {
        print("HealthKitManager init")
    } // Privato per Singleton

    let healthStore = HKHealthStore()

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        print("requestAutorization")
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
            
            let sharedDefaults = UserDefaults(suiteName: "group.climbTracker")
            self.fetchAverageQuantityLastMonth(for: .flightsClimbed) {
                f, error in
                print("avgFlightLastMonth \(f ?? 0)")
                self.avgFlightLastMonth = f ?? 0
            }
            self.fetchAverageQuantityLastMonth(for: .stepCount) {
                f, error in
                print("avgStepsLastMonth \(f ?? 0)")
                self.avgStepsLastMonth = f ?? 0
            }
            self.fetchFlightsClimbedToday { flightsClimbed, error in
                print("flightsClimbed \(flightsClimbed ?? 0)")
                self.lastFligth = flightsClimbed ?? 0
                sharedDefaults?.set(HealthKitManager.shared.lastFligth, forKey: "stairs")
            }
                
            self.fetchStepsTakenToday { stepsTaken, error in
                print("stepsTaken \(stepsTaken ?? 0)")
                self.lastStep = stepsTaken ?? 0
                sharedDefaults?.set(HealthKitManager.shared.lastStep, forKey: "steps")
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
                    print("maxflights \(daysCounted) \(flights)")
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

    func fetchAverageQuantityLastMonth(for identifier: HKQuantityTypeIdentifier, completion: @escaping (Double?, Error?) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            print("Nessun tipo di dato trovato per \(identifier)")
            completion(nil, nil) // Nessun tipo di dato trovato
            return
        }

        let now = Date()
        let calendar = Calendar.current

        guard let sixDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            completion(nil, nil) // Handle the error appropriately
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: sixDaysAgo, end: now, options: .strictStartDate)

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: sixDaysAgo, intervalComponents: interval)

        query.initialResultsHandler = { _, results, error in
            guard let statsCollection = results else {
                completion(nil, error)
                return
            }

            var totalQuantity: Double = 0
            var daysCounted: Double = 0
            statsCollection.enumerateStatistics(from: sixDaysAgo, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let quantity = sum.doubleValue(for: HKUnit.count())
                    print("units \(daysCounted) \(quantity)")
                    totalQuantity += quantity
                    if quantity > 0 {
                        daysCounted += 1
                    }
                }
            }

            let averageQuantity = daysCounted > 0 ? totalQuantity / daysCounted : 0
            completion(averageQuantity, nil)
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
        guard let sixDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            completion(nil, nil) // Handle the error appropriately
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: sixDaysAgo, end: now, options: .strictStartDate)

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: sixDaysAgo, intervalComponents: interval)
        
        query.initialResultsHandler = { query, results, error in
            guard let results = results else {
                completion(nil, error)
                return
            }
            
            var data: [Int: Double] = [:]

            results.enumerateStatistics(from: sixDaysAgo, to: now) { statistics, _ in
                let hour = Calendar.current.component(.day, from: statistics.startDate)
                let value = statistics.sumQuantity()?.doubleValue(for: HKUnit.count())
                data[hour] = value
                print("day \(hour) value \(value ?? 0)")
            }
            
            completion(data, nil)
        }
        
        healthStore.execute(query)
    }

    // Funzione per recuperare i dati dei passi degli ultimi 7 giorni
    func fetchLast7DaysSteps(completion: @escaping ([Double]?, Error?) -> Void) {
        fetchDataForLast7Days(forIdentifier: .stepCount, completion: completion)
    }

    // Funzione per recuperare i dati dei voli di scale degli ultimi 7 giorni
    func fetchLast7DaysFlights(completion: @escaping ([Double]?, Error?) -> Void) {
        fetchDataForLast7Days(forIdentifier: .flightsClimbed, completion: completion)
    }

    // Funzione di supporto per eseguire le query HealthKit per gli ultimi 7 giorni
    private func fetchDataForLast7Days(forIdentifier identifier: HKQuantityTypeIdentifier, completion: @escaping ([Double]?, Error?) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil, nil) // Tipo di dato non trovato
            return
        }

        let now = Date()
        let calendar = Calendar.current

        // Calcola la data di 7 giorni fa
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: yesterday) else {
            return
        }
        
        // Ottiene l'inizio del giorno per la data di 7 giorni fa
        let startOfSevenDaysAgo = calendar.startOfDay(for: sevenDaysAgo)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfSevenDaysAgo, end: now, options: .strictStartDate)

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: startOfSevenDaysAgo, intervalComponents: interval)

        query.initialResultsHandler = { _, results, error in
            guard let results = results else {
                completion(nil, error)
                return
            }

            var data: [Double] = []

            results.enumerateStatistics(from: startOfSevenDaysAgo, to: yesterday) { statistics, _ in
                let value = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                data.append(value)
            }

            completion(data, nil)
        }

        HKHealthStore().execute(query)
    }

    
}
