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
            progressSection
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
        if viewModel.isScanningLive {
            FaceScanPreviewView(session: viewModel.session)
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadiusToken.card, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.45), lineWidth: 2)
                            .padding(22)

                        VStack(spacing: SpacingToken.small) {
                            if let target = viewModel.currentTarget {
                                Text(target.title)
                                    .font(FontToken.heading)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(.black.opacity(0.42), in: Capsule())
                            }

                            ProgressView(value: viewModel.stabilityProgress)
                                .tint(.white)
                                .frame(maxWidth: 180)
                                .padding(.horizontal, 12)
                        }
                    }

                    if case .preparing = viewModel.state {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding(14)
                            .background(.black.opacity(0.4), in: Circle())
                    }

                    if case .capturing = viewModel.state {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding(14)
                            .background(.black.opacity(0.4), in: Circle())
                    }
                }
        } else if viewModel.state == .completed {
            completedPreviewView
        } else {
            permissionPlaceholderView
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        if viewModel.canRetake {
            Button(action: viewModel.retake) {
                Text("Scan Again")
                    .font(FontToken.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(ColorToken.primary)
                    .cornerRadius(CornerRadiusToken.card)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, SpacingToken.large)
        } else if viewModel.isScanningLive {
            VStack(spacing: SpacingToken.medium) {
                flashControl
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
            .disabled(!viewModel.isFlashAvailable)
            .onChange(of: viewModel.selectedFlashOption) { _, newOption in
                viewModel.updateFlashOption(newOption)
            }

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

            if viewModel.state == .requestingPermission || viewModel.state == .checkingPermission || viewModel.state == .preparing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(ColorToken.accent)
                    .scaleEffect(1.1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, SpacingToken.large)
    }

    private var progressSection: some View {
        VStack(spacing: SpacingToken.small) {
            HStack {
                Text("\(viewModel.capturedCount)/\(viewModel.totalCaptureCount) captured")
                    .font(FontToken.body)
                    .foregroundColor(ColorToken.textSecondary)
                Spacer()
            }

            ProgressView(value: viewModel.progressFraction)
                .tint(ColorToken.accent)

            HStack(spacing: SpacingToken.small) {
                ForEach(viewModel.captureOrder) { area in
                    Button {
                        viewModel.selectTargetArea(area)
                    } label: {
                        Text(area.title)
                            .font(.caption)
                            .foregroundColor(labelColor(for: area))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(backgroundColor(for: area), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.isAreaSelectable(area))
                    .opacity(viewModel.isAreaSelectable(area) ? 1 : 0.72)
                }
            }
        }
        .padding(.horizontal, SpacingToken.large)
    }

    private var completedPreviewView: some View {
        VStack(spacing: SpacingToken.small) {
            if let firstCapture = viewModel.capturedArtifacts.first,
               let image = viewModel.capturedPreviewByArea[firstCapture.area] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                ColorToken.surface
            }
        }
    }

    private func labelColor(for area: FaceScanArea) -> Color {
        if viewModel.isAreaCaptured(area) {
            return .white
        }

        if viewModel.currentTarget == area && viewModel.isScanningLive {
            return ColorToken.textPrimary
        }

        return ColorToken.textSecondary
    }

    private func backgroundColor(for area: FaceScanArea) -> Color {
        if viewModel.isAreaCaptured(area) {
            return ColorToken.accent
        }

        if viewModel.currentTarget == area && viewModel.isScanningLive {
            return ColorToken.primary.opacity(0.2)
        }

        return ColorToken.surface
    }
}

#Preview {
    NavigationStack {
        FaceScanView(viewModel: FaceScanViewModel(faceScanService: FaceScanSessionService()))
    }
}
