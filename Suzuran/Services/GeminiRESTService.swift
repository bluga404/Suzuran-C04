import Foundation

class GeminiRESTService {
    // Note: Put your API key here for testing
    private let apiKey = "" 
    private let model = "gemini-flash-latest"
    
    private let systemInstruction = """
    You are a Senior Dermatologist AI Assistant. Analyze the user's daily acne scan data and their skincare routine to provide actionable, safe, and encouraging insights.
    
    RULES:
    1. Analyze PROGRESS TREND (improving or worsening vs previous scan).
    2. Analyze INGREDIENT CORRELATION.
    3. Look for TRIGGERS (e.g. comedogenic oils).
    4. IMPORTANT: Do not give medical diagnoses. Use words like "may contribute to", "commonly used for".
    5. FORMATTING STRICTLY: Do NOT use markdown. Do NOT use introductory text. Each field MUST be exactly 1-2 concise sentences. Be objective and direct.
    """

    func generateInsight(scanScore: Int, acneCounts: [String: Int], ingredients: String, completion: @escaping (Result<InsightResponse, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key is missing. Please add it to GeminiRESTService."])))
            return
        }
        
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else { return }
        
        let acneDetails = acneCounts.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let promptText = "User's current skin score is \(scanScore)/100. Acne detected: \(acneDetails). They are currently using products with these ingredients: \(ingredients). Please analyze."
        
        let payload: [String: Any] = [
            "system_instruction": [
                "parts": [ ["text": systemInstruction] ]
            ],
            "contents": [
                ["parts": [ ["text": promptText] ]]
            ],
            "generationConfig": [
                "response_mime_type": "application/json",
                "response_schema": [
                    "type": "OBJECT",
                    "properties": [
                        "trend_summary": ["type": "STRING"],
                        "ingredient_insight": ["type": "STRING"],
                        "recommendation_to_add": ["type": "STRING"],
                        "recommendation_to_avoid": ["type": "STRING"],
                        "encouragement": ["type": "STRING"]
                    ],
                    "required": [
                        "trend_summary", 
                        "ingredient_insight", 
                        "recommendation_to_add", 
                        "recommendation_to_avoid", 
                        "encouragement"
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let textResult = firstPart["text"] as? String {
                    
                    guard let insightData = textResult.data(using: .utf8) else {
                        throw NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
                    }
                    let insight = try JSONDecoder().decode(InsightResponse.self, from: insightData)
                    completion(.success(insight))
                } else {
                    if let rawString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(rawString)")
                    }
                    completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
