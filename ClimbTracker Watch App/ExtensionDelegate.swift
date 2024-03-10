import ClockKit
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func applicationDidFinishLaunching() {
        print("applicationDidFinishLaunching")
        scheduleBackgroundRefresh()
    }
    
    func scheduleBackgroundRefresh() {
        // Scegli una data per il prossimo aggiornamento. Ad esempio, 15 minuti da ora.
        let nextUpdateTime = Date(timeIntervalSinceNow: 5 * 60)
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: nextUpdateTime, userInfo: nil) { (error) in
            if let error = error {
                print("Errore nella programmazione del background refresh: \(error)")
            } else {
                print("Background refresh programmato correttamente per \(nextUpdateTime)")
            }
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        print("handle")
        // Questo metodo verrà chiamato quando il sistema esegue il tuo background refresh task.
        for task in backgroundTasks {
            // Gestisci qui i diversi tipi di background tasks.
            if let refreshTask = task as? WKSnapshotRefreshBackgroundTask {
                let group = DispatchGroup()

                group.enter()
                HealthKitManager.shared.fetchFlightsClimbedToday { flightsClimbed, error in
                    print("flightsClimbed \(flightsClimbed ?? 0)")
                    HealthKitManager.shared.lastFligth = flightsClimbed ?? 0
                    group.leave()
                }
                    
                group.enter()
                HealthKitManager.shared.fetchStepsTakenToday { stepsTaken, error in
                    print("stepsTaken \(stepsTaken ?? 0)")
                    HealthKitManager.shared.lastStep = stepsTaken ?? 0
                    group.leave()
                }

                group.notify(queue: .main) {
                    print("Both tasks are completed.")
                    
                    let sharedDefaults = UserDefaults(suiteName: "group.climbTracker")
                    sharedDefaults?.set(HealthKitManager.shared.lastStep, forKey: "steps")
                    sharedDefaults?.set(HealthKitManager.shared.lastFligth, forKey: "stairs")
                    
                    // Dopo aver completato il lavoro di aggiornamento, chiama setTaskCompletedWithSnapshot per terminare il task.
                    refreshTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date().addingTimeInterval(300), userInfo: nil)
                    
                    // Pianifica il prossimo background refresh.
                    self.scheduleBackgroundRefresh()

                }
            } else if let refreshTask = task as? WKApplicationRefreshBackgroundTask {
                let group = DispatchGroup()

                group.enter()
                HealthKitManager.shared.fetchFlightsClimbedToday { flightsClimbed, error in
                    print("flightsClimbed \(flightsClimbed ?? 0)")
                    HealthKitManager.shared.lastFligth = flightsClimbed ?? 0
                    group.leave()
                }
                    
                group.enter()
                HealthKitManager.shared.fetchStepsTakenToday { stepsTaken, error in
                    print("stepsTaken \(stepsTaken ?? 0)")
                    HealthKitManager.shared.lastStep = stepsTaken ?? 0
                    group.leave()
                }

                group.notify(queue: .main) {
                    print("Both tasks are completed.")
                    
                    let sharedDefaults = UserDefaults(suiteName: "group.climbTracker")
                    sharedDefaults?.set(HealthKitManager.shared.lastStep, forKey: "steps")
                    sharedDefaults?.set(HealthKitManager.shared.lastFligth, forKey: "stairs")
                    
                    // Dopo aver completato il lavoro di aggiornamento, chiama setTaskCompletedWithSnapshot per terminare il task.
                    refreshTask.setTaskCompleted()
                    
                    // Pianifica il prossimo background refresh.
                    self.scheduleBackgroundRefresh()

                }
            }
        }
    }
}
