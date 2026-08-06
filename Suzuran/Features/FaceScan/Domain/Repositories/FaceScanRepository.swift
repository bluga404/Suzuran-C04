import Foundation

protocol FaceScanRepository {
    func detectAcne(in imageData: Data) async throws -> [AcneDetection]
    func saveScanSession(_ session: FaceScanSession) async throws
    func scanHistory() async throws -> [FaceScanSession]
}
