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
        // Questo metodo verrà chiamato quando il sistema esegue il tuo background refresh task.
        for task in backgroundTasks {
            // Gestisci qui i diversi tipi di background tasks.
            if let refreshTask = task as? WKApplicationRefreshBackgroundTask {
                // Esegui qui il lavoro di aggiornamento necessario.
                
                // Esempio: aggiornamento della complication.
                let server = CLKComplicationServer.sharedInstance()
                for complication in server.activeComplications ?? [] {
                    server.reloadTimeline(for: complication)
                }
                
                // Dopo aver completato il lavoro di aggiornamento, chiama setTaskCompletedWithSnapshot per terminare il task.
                refreshTask.setTaskCompletedWithSnapshot(false)
                
                // Pianifica il prossimo background refresh.
                scheduleBackgroundRefresh()
            }
        }
    }
}
