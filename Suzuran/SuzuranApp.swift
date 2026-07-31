//
//  SuzuranApp.swift
//  Suzuran
//
//  Created by Robby Yehezkiel Pardomuan on 31/07/26.
//

import SwiftUI

@main
struct SuzuranApp: App {
    @StateObject private var appRouter = AppRouter()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appRouter)
        }
    }
}
