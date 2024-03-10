//
//  AppIntent.swift
//  multiWidget
//
//  Created by Roberto Viola on 10/03/24.
//

import WidgetKit
import AppIntents

@available(watchOSApplicationExtension 10.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}
