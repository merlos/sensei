//
//  SenseiWidgetLiveActivity.swift
//  SenseiWidget
//
//  Created by Merlos on 11/25/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SenseiWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

// Live Activities are not used in this app - only home screen widgets
// If you want to enable Live Activities in the future, uncomment this code

/*
struct SenseiWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SenseiWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}
*/

extension SenseiWidgetAttributes {
    fileprivate static var preview: SenseiWidgetAttributes {
        SenseiWidgetAttributes(name: "World")
    }
}

extension SenseiWidgetAttributes.ContentState {
    fileprivate static var smiley: SenseiWidgetAttributes.ContentState {
        SenseiWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SenseiWidgetAttributes.ContentState {
         SenseiWidgetAttributes.ContentState(emoji: "🤩")
     }
}

/*
#Preview("Notification", as: .content, using: SenseiWidgetAttributes.preview) {
   SenseiWidgetLiveActivity()
} contentStates: {
    SenseiWidgetAttributes.ContentState.smiley
    SenseiWidgetAttributes.ContentState.starEyes
}
*/
