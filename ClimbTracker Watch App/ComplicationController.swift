import ClockKit
import WatchKit
import Foundation

class ComplicationController: NSObject, CLKComplicationDataSource, WKExtensionDelegate {
    
    var lastStep = 0.0
    var lastFlight = 0.0
    
    func applicationDidFinishLaunching() {
        // Pianifica il primo background refresh dopo l'avvio dell'app.
        scheduleBackgroundRefresh()
    }
    
    func scheduleBackgroundRefresh() {
        // Scegli una data per il prossimo aggiornamento. Ad esempio, 15 minuti da ora.
        let nextUpdateTime = Date(timeIntervalSinceNow: 2 * 60)
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
                                
                HealthKitManager.shared.fetchFlightsClimbedToday { [self]
                    f, error in
                    if(f ?? 0 != self.lastFlight) {
                        self.lastFlight = f ?? 0
                        let server = CLKComplicationServer.sharedInstance()
                        for complication in server.activeComplications ?? [] {
                            server.reloadTimeline(for: complication)
                        }

                    }
                }
                HealthKitManager.shared.fetchStepsTakenToday { [self]
                    f, error in
                    if(f ?? 0 > self.lastStep + 500) {
                        self.lastStep = f ?? 0
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
    }
            
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        print("getCurrentTimelineEntry")
        // Mostra i piani saliti
        HealthKitManager.shared.fetchFlightsClimbedToday { flightsClimbed, error in
            guard let flightsClimbed = flightsClimbed else {
                print("flights error")
                handler(nil)
                return
            }
            print("flightsClimbed \(flightsClimbed)")
            
            HealthKitManager.shared.fetchStepsTakenToday { [flightsClimbed] stepsTaken, error in
                guard let stepsTaken = stepsTaken else {
                    print("step error")
                    handler(nil)
                    return
                }
                
                print("stepsTaken \(stepsTaken)")
                
                if(complication.identifier == "complication1") {
                    let template = self.createStackImageTemplate(value: flightsClimbed, unit: "flights", icon: /*UIImage(named: "StepsIcon")!*/ UIImage())
                    if let template = template {
                        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                        handler(entry)
                    } else {
                        handler(nil)
                    }
                } else {
                    let template = self.createStackImageTemplate(value: stepsTaken, unit: "steps", icon: /*UIImage(named: "StepsIcon")!*/ UIImage())
                    if let template = template {
                        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                        handler(entry)
                    } else {
                        handler(nil)
                    }
                }
            }
        }
    }
    
    private func templateForComplication(complication: CLKComplication) -> CLKComplicationTemplate? {
            // Init default output:
            var template: CLKComplicationTemplate? = nil
            
            // Graphic Complications are only availably since watchOS 5.0:
            if #available(watchOSApplicationExtension 5.0, *) {
                // NOTE: Watch faces that support graphic templates are available only on Apple Watch Series 4 or later. So the binary on older devices (e.g. Watch Series 3) will not contain the images.
                if complication.family == .graphicCircular {
                    let imageTemplate = CLKComplicationTemplateGraphicCircularImage()
                    // Check if asset exists, to prevent crash on non-supported devices:
                    if let fullColorImage = UIImage(named: "Complication/Graphic Circular") {
                        let imageProvider = CLKFullColorImageProvider.init(fullColorImage: fullColorImage)
                        imageTemplate.imageProvider = imageProvider
                        template = imageTemplate
                    }
                }
                else if complication.family == .graphicCorner {
                    let imageTemplate = CLKComplicationTemplateGraphicCornerCircularImage()
                    // Check if asset exists, to prevent crash on non-supported devices:
                    if let fullColorImage = UIImage(named: "Complication/Graphic Corner") {
                        let imageProvider = CLKFullColorImageProvider.init(fullColorImage: fullColorImage)
                        imageTemplate.imageProvider = imageProvider
                        template = imageTemplate
                    }
                }
            }
            
            // For all watchOS versions:
            if complication.family == .circularSmall {
                template = createStackImageTemplate(value: 0, unit: "", icon: UIImage())
            }
            else if complication.family == .modularSmall {
                template = createStackImageTemplate(value: 0, unit: "", icon: UIImage())
            }
            else if complication.family == .utilitarianSmall {
                let imageTemplate = CLKComplicationTemplateUtilitarianSmallSquare()
                let imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
                imageProvider.tintColor = UIColor.blue
                imageTemplate.imageProvider = imageProvider
                template = imageTemplate
            }
            
            return template
        }
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        print("getComplicationDescriptors")
           let descriptor1 = CLKComplicationDescriptor(
               identifier: "complication1",
               displayName: "Flights",
               supportedFamilies: [.graphicCircular] // Aggiungi qui altre famiglie supportate
               // Puoi specificare un'opzione di preview per ogni descriptor
           )
           
            let descriptor2 = CLKComplicationDescriptor(
                identifier: "complication2",
                displayName: "Steps",
                supportedFamilies: [.graphicCircular] // Aggiungi qui altre famiglie supportate
                // Puoi specificare un'opzione di preview per ogni descriptor
            )
           // Crea altri descriptors per altre complications se necessario
           
           // Restituisci un array di tutti i descriptors
           handler([descriptor1, descriptor2])
       }
    
    private func createStackImageTemplate(value: Double, unit: String, icon: UIImage) -> CLKComplicationTemplate? {
        print("createStackImageTemplate")
        var combinedTextProvider : CLKSimpleTextProvider
        
        var fraction : Float = 0.0
        var color : UIColor = .red

        if(unit=="steps") {
            fraction = Float(Int(value) % 1000) / 1000.0
            let v = value / 1000
            var k = "K"
            if(v >= 10) {
                k = ""
            }
            combinedTextProvider = CLKSimpleTextProvider(text: "\(Int(v))" + k, shortText: "\(unit)")
            let f = Float(value) / Float(HealthKitManager.shared.maxStepsLastMonth)
            if(f < 0.30) {
                color = .orange
            } else if(fraction < 0.60) {
                color = .yellow
            } else if(fraction >= 1) {
                color = .green
            }
        } else {
            fraction = Float(value) / Float(HealthKitManager.shared.maxFlightLastMonth)
            if(fraction > 1) {
                fraction = 1
            }
            combinedTextProvider = CLKSimpleTextProvider(text: "\(Int(value))", shortText: "\(unit)")
            if(fraction < 0.30) {
                color = .orange
            } else if(fraction < 0.60) {
                color = .yellow
            } else if(fraction >= 1) {
                color = .green
            }
        }
            
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                  gaugeColor: color,
                                                  fillFraction: fraction)

        // Configura il template della complication
        let closedGaugeTextTemplate = CLKComplicationTemplateGraphicCircularClosedGaugeText(gaugeProvider: gaugeProvider, centerTextProvider: combinedTextProvider)

        return closedGaugeTextTemplate
    }
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
            handler([.forward, .backward])
        }
        
        func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
            handler(nil)
        }
        
        func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
            handler(nil)
        }
        
        func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
            handler(.showOnLockScreen)
        }
        
        // MARK: - Timeline Population
                
        func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
            // Call the handler with the timeline entries prior to the given date
            handler(nil)
        }
        
        func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
            // Call the handler with the timeline entries after to the given date
            handler(nil)
        }
        
        func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
            // This method will be called once per supported complication, and the results will be cached
            handler(templateForComplication(complication: complication))
        }
        // MARK: - Placeholder Templates
        
        func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
            // This method will be called once per supported complication, and the results will be cached
            handler(templateForComplication(complication: complication))
        }
}
