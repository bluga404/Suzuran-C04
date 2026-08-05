//
//  IngredientOCRView.swift
//  IngredientOCR
//
//  Created by Dinda Putri Pamungkas  on 02/08/26.
//

import SwiftUI

struct IngredientOCRView: View {
    let image: UIImage

    @State private var rawText = ""
    @State private var ingredients: [String] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let ocrService = IngredientOCRService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 260)

            Button(isProcessing ? "Extracting..." : "Extract Ingredients") {
                Task {
                    await runOCR()
                }
            }
            .disabled(isProcessing)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Text("Detected Ingredients")
                .font(.headline)

            List(ingredients, id: \.self) { ingredient in
                Text(ingredient)
            }

            DisclosureGroup("Raw OCR Text") {
                Text(rawText)
                    .font(.caption)
                    .textSelection(.enabled)
            }
        }
        .padding()
    }

    private func runOCR() async {
        isProcessing = true
        errorMessage = nil

        do {
            let text = try await ocrService.recognizeText(from: image)
            rawText = text
            ingredients = IngredientParser.extractIngredients(from: text)
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }
}
