//
//  CameraService.swift
//  Suzuran
//
//  Created by Walker Valentinus Simanjuntak on 04/08/26.
//

import AVFoundation
import UIKit

class CameraService: NSObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var captureCompletion: ((UIImage) -> Void)?
    private var currentInput: AVCaptureDeviceInput?

    var onFrameCaptured: ((CMSampleBuffer) -> Void)?
    private(set) var cameraPosition: AVCaptureDevice.Position = .back

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startSession() {
        guard let device = defaultDevice(for: cameraPosition) else { return }

        guard let input = try? AVCaptureDeviceInput(device: device) else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }
        if session.canAddOutput(output) { session.addOutput(output) }
        if session.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.queue"))
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stopSession() {
        session.stopRunning()
    }

    func toggleCamera() {
        let newPosition: AVCaptureDevice.Position = (cameraPosition == .back) ? .front : .back
        guard
            let device = defaultDevice(for: newPosition),
            let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        session.beginConfiguration()
        if let currentInput {
            session.removeInput(currentInput)
        }
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }
        session.commitConfiguration()
        cameraPosition = newPosition
    }

    private func defaultDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onFrameCaptured?(sampleBuffer)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        captureCompletion?(image)
        captureCompletion = nil
    }
}
