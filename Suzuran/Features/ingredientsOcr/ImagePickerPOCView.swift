//
//  ImagePickerPOCView.swift
//  IngredientOCR
//
//  Created by Dinda Putri Pamungkas  on 02/08/26.
//

import SwiftUI
import PhotosUI

struct ImagePickerPOCView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isShowingCamera = false

    var body: some View {
        VStack(spacing: 20) {
                PhotosPicker("Choose Ingredient Label", selection: $selectedItem, matching: .images)

                Button("Take Photo") {
                    isShowingCamera = true
                }

                if let selectedImage {
                    NavigationLink("Open OCR", destination: IngredientOCRView(image: selectedImage))
                }
            }
            .padding()
            .navigationTitle("Ingredient OCR")
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                CameraPicker(selectedImage: $selectedImage)
            }
    }
}
