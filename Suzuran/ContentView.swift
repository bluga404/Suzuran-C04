//
//  ContentView.swift
//  Suzuran
//
//  Modified by Walker

import SwiftUI
import FirebaseAI

struct ContentView: View {
    let model = FirebaseAI.firebaseAI(backend: .googleAI())
        .generativeModel(modelName: "gemini-3.6-flash")

    @State private var userPrompt = ""
    @State private var aiResponse = ""
    @State private var isLoading = false

    var body: some View {
        VStack {
            Text("Gemini AI")
                .font(.largeTitle)

            ScrollView {
                Text(aiResponse.isEmpty ? "Ask me anything..." : aiResponse)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack {
                TextField("Ask a question...", text: $userPrompt)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task {
                        await sendMessage()
                    }
                } label: {
                    Image(systemName: isLoading ? "ellipsis" : "paperplane.fill")
                        .font(.title2)
                }
                .disabled(userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
        .padding()
    }

    @MainActor
    func sendMessage() async {
        let prompt = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        userPrompt = ""
        isLoading = true
        aiResponse = ""

        do {
            let response = try await model.generateContent(prompt)
            aiResponse = response.text ?? "No response found"
        } catch {
            aiResponse = Self.format(error: error)
        }

        isLoading = false
    }

    private static func format(error: Error) -> String {
        let nsError = error as NSError
        var message = "Error: \(nsError.localizedDescription)"

        if !nsError.domain.isEmpty {
            message += "\nDomain: \(nsError.domain)"
        }

        message += "\nCode: \(nsError.code)"

        if let reason = nsError.localizedFailureReason, !reason.isEmpty {
            message += "\nReason: \(reason)"
        }

        if let suggestion = nsError.localizedRecoverySuggestion, !suggestion.isEmpty {
            message += "\nSuggestion: \(suggestion)"
        }

        return message
    }
}

#Preview {
    ContentView()
}
