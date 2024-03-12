//
//  ClimbTrackerApp.swift
//  ClimbTracker Watch App
//
//  Created by Roberto Viola on 25/02/24.
//

import SwiftUI

@main
struct ClimbTracker_Watch_AppApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView(inPreview: false)
        }
    }
}
