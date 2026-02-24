//
//  _demoApp.swift
//  2demo
//
//  Created by shashi kiran  on 24/02/2026.
//

import SwiftUI
import CoreData

@main
struct _demoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
