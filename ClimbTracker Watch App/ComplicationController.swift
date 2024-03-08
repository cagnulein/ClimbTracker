import ClockKit
import Foundation

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    var showSteps = false
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        print("getCurrentTimelineEntry")
        if showSteps {
            // Mostra i passi fatti
            HealthKitManager.shared.fetchStepsTakenToday { stepsTaken, error in
                guard let stepsTaken = stepsTaken else {
                    print("step error")
                    handler(nil)
                    return
                }
                
                print("stepsTaken \(stepsTaken)")
                
                let template = self.createStackImageTemplate(value: stepsTaken, unit: "passi", icon: /*UIImage(named: "StepsIcon")!*/ UIImage())
                if let template = template {
                    let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                    handler(entry)
                } else {
                    handler(nil)
                }
                
                self.showSteps.toggle()
            }
        } else {
            // Mostra i piani saliti
            HealthKitManager.shared.fetchFlightsClimbedToday { flightsClimbed, error in
                guard let flightsClimbed = flightsClimbed else {
                    print("flights error")
                    handler(nil)
                    return
                }
                print("flightsClimbed \(flightsClimbed)")
                
                let template = self.createStackImageTemplate(value: flightsClimbed, unit: "piani", icon: /*UIImage(named: "FlightsIcon")!*/ UIImage())
                if let template = template {
                    let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                    handler(entry)
                } else {
                    handler(nil)
                }
                
                self.showSteps.toggle()
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
                template = createStackImageTemplate(value: 0, unit: "passi", icon: UIImage())
            }
            else if complication.family == .modularSmall {
                template = createStackImageTemplate(value: 0, unit: "passi", icon: UIImage())
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
               displayName: "Piani Saliti",
               supportedFamilies: [.graphicCircular] // Aggiungi qui altre famiglie supportate
               // Puoi specificare un'opzione di preview per ogni descriptor
           )
           
           // Crea altri descriptors per altre complications se necessario
           
           // Restituisci un array di tutti i descriptors
           handler([descriptor1])
       }
    
    private func createStackImageTemplate(value: Double, unit: String, icon: UIImage) -> CLKComplicationTemplate? {
        print("createStackImageTemplate")
        let centerTextProvider = CLKSimpleTextProvider(text: String(value))

           // Crea il fornitore di gauge per indicare il progresso
           // Qui si assume un valore di esempio del 75% per il progresso
           let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                      gaugeColor: .red,
                                                      fillFraction: Float(value) / Float(HealthKitManager.shared.maxFlightLastMonth))
           
           // Configura il template della complication
           let closedGaugeTextTemplate = CLKComplicationTemplateGraphicCircularClosedGaugeText(gaugeProvider: gaugeProvider, centerTextProvider: centerTextProvider)
           
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
