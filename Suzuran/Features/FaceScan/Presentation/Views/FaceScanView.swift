import AVFoundation
import SwiftUI

struct FaceScanView: View {
    @StateObject private var viewModel: FaceScanViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: FaceScanViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: SpacingToken.large) {
            headerSection
            previewSection
            actionSection

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(FontToken.body)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SpacingToken.large)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, SpacingToken.medium)
        .navigationTitle("FaceScan")
        .navigationBarTitleDisplayMode(.inline)
        .background(ColorToken.background.ignoresSafeArea())
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .onChange(of: scenePhase) { _, newPhase in
            viewModel.handleScenePhaseChange(newPhase)
        }
    }

    private var headerSection: some View {
        VStack(spacing: SpacingToken.small) {
            Text(viewModel.titleText)
                .font(FontToken.heading)
                .foregroundColor(ColorToken.textPrimary)
                .multilineTextAlignment(.center)

            Text(viewModel.messageText)
                .font(FontToken.body)
                .foregroundColor(ColorToken.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, SpacingToken.large)
    }

    private var previewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadiusToken.card, style: .continuous)
                .fill(ColorToken.surface)

            previewContent
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadiusToken.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadiusToken.card, style: .continuous)
                .stroke(ColorToken.divider, lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
        .aspectRatio(3 / 4, contentMode: .fit)
        .padding(.horizontal, SpacingToken.large)
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    @ViewBuilder
    private var previewContent: some View {
        if let capturedImage = viewModel.capturedImage {
            Image(uiImage: capturedImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else if viewModel.canCapture || viewModel.state == .captureInProgress || viewModel.state == .startingSession {
            FaceScanPreviewView(session: viewModel.session)
                .overlay {
                    if viewModel.state == .startingSession || viewModel.state == .captureInProgress {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding(14)
                            .background(.black.opacity(0.4), in: Circle())
                    }
                }
        } else {
            permissionPlaceholderView
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        if viewModel.hasCapturedImage {
            Button(action: viewModel.retake) {
                Text("Capture Another FaceScan")
                    .font(FontToken.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(ColorToken.primary)
                    .cornerRadius(CornerRadiusToken.card)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, SpacingToken.large)
        } else if viewModel.canCapture || viewModel.state == .captureInProgress {
            VStack(spacing: SpacingToken.medium) {
                flashControl

                Button(action: viewModel.captureFaceScan) {
                    Text(viewModel.captureButtonTitle)
                        .font(FontToken.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(ColorToken.accent)
                        .cornerRadius(CornerRadiusToken.card)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canCapture)
                .opacity(viewModel.canCapture ? 1 : 0.65)
            }
            .padding(.horizontal, SpacingToken.large)
        } else {
            permissionActions
        }
    }

    private var permissionActions: some View {
        VStack(spacing: SpacingToken.medium) {
            if viewModel.authorizationStatus == .notDetermined {
                Button("Continue") {
                    viewModel.requestPermissionAndStartIfNeeded()
                }
                .font(FontToken.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(ColorToken.accent)
                .cornerRadius(CornerRadiusToken.card)
                .buttonStyle(.plain)
            }

            if viewModel.shouldShowSettingsButton {
                Button("Open Settings") {
                    guard let settingsURL = AppSettingsURLProvider.appSettingsURL() else { return }
                    openURL(settingsURL)
                }
                .font(FontToken.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(ColorToken.primary)
                .cornerRadius(CornerRadiusToken.card)
                .buttonStyle(.plain)
            }

            if viewModel.isInFailureState {
                Button("Try Again") {
                    viewModel.retry()
                }
                .font(FontToken.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(ColorToken.secondary)
                .cornerRadius(CornerRadiusToken.card)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, SpacingToken.large)
    }

    @ViewBuilder
    private var flashControl: some View {
        VStack(spacing: SpacingToken.small) {
            HStack {
                Label("Flash", systemImage: "bolt.fill")
                    .font(FontToken.body)
                    .foregroundColor(ColorToken.textPrimary)
                Spacer()
            }

            Picker("Flash", selection: $viewModel.selectedFlashOption) {
                ForEach(viewModel.availableFlashOptions) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.state == .captureInProgress || !viewModel.isFlashAvailable)

            if !viewModel.isFlashAvailable {
                Text("Flash is not available for this front-camera setup.")
                    .font(.footnote)
                    .foregroundColor(ColorToken.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var permissionPlaceholderView: some View {
        VStack(spacing: SpacingToken.medium) {
            Image(systemName: "camera.fill")
                .font(.system(size: 42))
                .foregroundColor(ColorToken.secondary)

            if viewModel.state == .requestingPermission || viewModel.state == .checkingPermission || viewModel.state == .startingSession {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(ColorToken.accent)
                    .scaleEffect(1.1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, SpacingToken.large)
    }
}

#Preview {
    NavigationStack {
        FaceScanView(viewModel: FaceScanViewModel(faceScanService: FaceScanSessionService()))
    }
}
