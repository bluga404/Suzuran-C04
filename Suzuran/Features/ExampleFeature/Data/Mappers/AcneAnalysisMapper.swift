import Foundation

enum AcneAnalysisMapper {
    static func map(_ dto: AcneAnalysisResponseDTO) throws -> AcneAnalysis {
        guard let severity = AcneSeverity(rawValue: dto.severity) else {
            throw AcneAnalysisDomainError.invalidPayload(field: "severity")
        }

        let findings = try dto.findings.map { finding in
            guard let zone = FaceZone(rawValue: finding.zone) else {
                throw AcneAnalysisDomainError.invalidPayload(field: "zone")
            }

            return AcneFinding(
                id: finding.id,
                zone: zone,
                lesionCount: finding.lesionCount,
                inflammationLevel: finding.inflammationLevel
            )
        }

        return AcneAnalysis(
            id: dto.id,
            capturedAt: dto.capturedAt,
            overallSeverity: severity,
            confidence: dto.confidence,
            findings: findings,
            recommendation: dto.recommendation
        )
    }
}
