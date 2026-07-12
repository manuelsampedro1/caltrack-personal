import Foundation
import UIKit

struct GrokService {
    static let apiKeyAccount = "xai-api-key"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func validateAPIKey(_ apiKey: String) async throws {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GrokError.missingAPIKey
        }
        var request = URLRequest(url: URL(string: "https://api.x.ai/v1/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GrokError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 { throw GrokError.invalidAPIKey }
            let message = Self.errorMessage(from: data) ?? "xAI devolvió el código \(http.statusCode)."
            throw GrokError.api(message)
        }
    }

    func analyze(image: UIImage, apiKey: String) async throws -> FoodAnalysis {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GrokError.missingAPIKey
        }
        guard let imageData = image.caltrackJPEGData() else {
            throw GrokError.invalidImage
        }

        var request = URLRequest(url: URL(string: "https://api.x.ai/v1/responses")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: Self.requestBody(imageData: imageData))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GrokError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = Self.errorMessage(from: data) ?? "xAI devolvió el código \(http.statusCode)."
            throw GrokError.api(message)
        }
        return try Self.decodeResponse(data)
    }

    static func decodeResponse(_ data: Data) throws -> FoodAnalysis {
        let envelope = try JSONDecoder().decode(ResponseEnvelope.self, from: data)
        guard let text = envelope.output
            .flatMap({ $0.content ?? [] })
            .first(where: { $0.type == "output_text" })?.text,
              let payload = text.data(using: .utf8) else {
            throw GrokError.invalidResponse
        }
        return try JSONDecoder().decode(FoodAnalysis.self, from: payload)
    }

    private static func requestBody(imageData: Data) -> [String: Any] {
        let imageURL = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
        return [
            "model": "grok-4.5",
            "store": false,
            "input": [[
                "role": "user",
                "content": [
                    ["type": "input_image", "image_url": imageURL, "detail": "high"],
                    ["type": "input_text", "text": prompt]
                ]
            ]],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "food_analysis",
                    "strict": true,
                    "schema": schema
                ]
            ]
        ]
    }

    private static let prompt = """
    Analiza esta comida como asistente de registro nutricional. Identifica cada componente visible, estima porciones realistas y calcula calorías, proteína, carbohidratos y grasa. Ten en cuenta aceites, salsas y bebidas visibles. No inventes certeza: usa confidence entre 0 y 1, explica los supuestos de cantidad y añade una advertencia breve cuando un ingrediente oculto pueda cambiar mucho el total. Responde únicamente con el esquema solicitado. Los valores son estimaciones para que el usuario los corrija antes de guardar.
    """

    private static let number: [String: Any] = ["type": "number", "minimum": 0]
    private static let schema: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["title", "items", "calories", "protein_g", "carbs_g", "fat_g", "confidence", "assumptions", "warning"],
        "properties": [
            "title": ["type": "string"],
            "items": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["name", "portion", "calories", "protein_g", "carbs_g", "fat_g"],
                    "properties": [
                        "name": ["type": "string"],
                        "portion": ["type": "string"],
                        "calories": number,
                        "protein_g": number,
                        "carbs_g": number,
                        "fat_g": number
                    ]
                ]
            ],
            "calories": number,
            "protein_g": number,
            "carbs_g": number,
            "fat_g": number,
            "confidence": ["type": "number", "minimum": 0, "maximum": 1],
            "assumptions": ["type": "array", "items": ["type": "string"]],
            "warning": ["type": "string"]
        ]
    ]

    private static func errorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = object["error"] as? [String: Any] else { return nil }
        return error["message"] as? String
    }
}

private struct ResponseEnvelope: Decodable {
    struct Output: Decodable {
        struct Content: Decodable {
            let type: String
            let text: String?
        }
        let content: [Content]?
    }
    let output: [Output]
}

enum GrokError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case invalidImage
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "Añade tu clave de xAI en Ajustes para analizar fotos con Grok."
        case .invalidAPIKey: "La clave de xAI no es válida."
        case .invalidImage: "No se pudo preparar esta foto."
        case .invalidResponse: "Grok respondió con un formato que Caltrack no reconoce."
        case .api(let message): message
        }
    }
}

private extension UIImage {
    func caltrackJPEGData(maxDimension: CGFloat = 1_600, compression: CGFloat = 0.78) -> Data? {
        let longest = max(size.width, size.height)
        let scale = min(1, maxDimension / max(longest, 1))
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in draw(in: CGRect(origin: .zero, size: target)) }
        return resized.jpegData(compressionQuality: compression)
    }
}
