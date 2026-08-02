# Naming Conventions

## General Naming

- Types: `UpperCamelCase`.
- Variables/functions/properties: `lowerCamelCase`.
- Protocols:
  - Noun when representing abstraction (`AcneAnalysisRepository`).
  - Capability suffix when appropriate (`SomethingLogging`, `SomethingProviding`).

## File Naming

- One primary type per file.
- File name equals primary type name.
- Suffix strategy by role:
  - `...View`
  - `...ViewModel`
  - `...UseCase`
  - `...Repository`
  - `...Mapper`
  - `...DTO`
  - `...Factory`

## Folder Naming

- Use plural for category folders: `UseCases`, `Repositories`, `Entities`, `ViewModels`.
- Use feature-first grouping under `Features/<FeatureName>`.

## Function Naming

- Side-effect functions: imperative verbs (`loadHistory`, `analyzeSampleImage`).
- Value-returning non-mutating functions: noun/verb phrase (`map`, `history`).

## Documentation Naming

- Start summary comments with what the symbol does.
- Keep documentation concise and role-based.
- Use Swift symbol markup where needed:
  - `- Parameter`
  - `- Returns`
  - `- Throws`
  - `- Warning`

## Avoid

- Type names in variable names when role is clearer.
- Abbreviations with unclear meaning.
- Generic file names like `Helper.swift` when role can be explicit.
