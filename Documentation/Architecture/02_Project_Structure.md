# Project Structure

## Current Folder Structure

```text
Suzuran/
  App/
    AppBootstrapper.swift
    AppContainer.swift
    AppEnvironment.swift
    Navigation/
      AppRoute.swift
      AppRouter.swift
    Root/
      RootView.swift
      RootViewModel.swift

  Core/
    DesignSystem/
      Components/
        AppCard.swift
        AppTextField.swift
        PrimaryButton.swift
        StateViews/
          EmptyStateView.swift
          ErrorStateView.swift
          LoadingStateView.swift
          OfflineStateView.swift
          PermissionStateView.swift
      Modifiers/
        ScreenContainerModifier.swift
      Tokens/
        AppColor.swift
        AppCornerRadius.swift
        AppSpacing.swift
        AppTypography.swift
    Error/
      AppError.swift
      AppErrorMapper.swift
    Foundation/
      AppConstants.swift
    Logging/
      AppLogger.swift
    State/
      LoadableState.swift

  Features/
    ExampleFeature/
      Composition/
        ExampleFeatureFactory.swift
      Domain/
        Entities/
          AcneAnalysis.swift
        Errors/
          AcneAnalysisDomainError.swift
        Repositories/
          AcneAnalysisRepository.swift
        UseCases/
          AnalyzeAcneFromImageUseCase.swift
          GetAcneAnalysisHistoryUseCase.swift
      Data/
        DTOs/
          AcneAnalysisResponseDTO.swift
        DataSources/
          Local/
            AcneHistoryLocalDataSource.swift
            InMemoryAcneHistoryLocalDataSource.swift
          Remote/
            AcneDetectionRemoteDataSource.swift
            MockAcneDetectionRemoteDataSource.swift
        Mappers/
          AcneAnalysisMapper.swift
        Repositories/
          DefaultAcneAnalysisRepository.swift
      Presentation/
        Mapping/
          ExampleFeatureErrorTextMapper.swift
          ExampleFeaturePresentationMapper.swift
        Models/
          ExampleFeatureViewState.swift
        ViewModels/
          ExampleFeatureViewModel.swift
        Views/
          ExampleFeatureView.swift

  Infrastructure/
    Networking/
      Endpoint.swift
      HTTPClient.swift
      HTTPMethod.swift
      URLSessionHTTPClient.swift
    Persistence/
      KeyValueStore.swift
      UserDefaultsKeyValueStore.swift

  LaunchScreen.storyboard
  SuzuranApp.swift
```

## Folder Strategy

- Group by bounded context first (`Features`, `Core`, `Infrastructure`, `App`).
- Inside `Features`, group by feature name.
- Inside each feature, group by architecture layer (`Domain`, `Data`, `Presentation`, `Composition`).
- Keep Core framework-agnostic where practical.
- Implement use cases directly in each feature's `Domain/UseCases` folder without a shared Core use case base protocol.
