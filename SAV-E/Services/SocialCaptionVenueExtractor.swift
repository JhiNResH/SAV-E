import Foundation

/// One venue the LLM believes a social caption is primarily about.
///
/// This is intentionally minimal: the deterministic parser already owns
/// marker-driven extraction (📍 pins, address lines, @handles). The LLM only
/// supplies a *name* (plus loose area/category hints) for the prose-only long
/// tail the deterministic parser deliberately rejects to avoid false positives.
/// Coordinates are never produced here — an extracted venue is only ever a
/// Review Candidate stem, never a Map Stamp.
struct ExtractedVenue: Equatable {
    /// The venue's proper name, as it literally appears in the caption.
    var name: String
    /// City / neighborhood / country hint, if the caption named one.
    var area: String?
    /// Loose category hint: cafe/food/bar/hotel/attraction/shopping/stay.
    var category: String?
    /// LLM self-reported confidence, 0...1.
    var confidence: Double
}

/// Extracts the primary venue name from a social caption when the deterministic
/// marker-driven parser found nothing. Injectable so tests can supply a fake
/// (no network); production uses the Gemini-backed implementation below.
protocol SocialCaptionVenueExtractor {
    func extractVenue(caption: String, sourceURL: String) async -> ExtractedVenue?
}

/// Live extractor backed by the shared backend Gemini proxy (the same transport
/// `GeminiSaveLLMClient` uses). Works for real Privy users *and* the App Review
/// demo guest, because the transport falls back to the `x-save-guest-token`
/// header when no Privy JWT is available.
///
/// Honest runtime note: in production this depends on the live proxy returning a
/// well-formed extraction. It is bounded (single attempt + the transport's own
/// transient retry, a hard timeout, capped output) and fails safe to `nil` on
/// any error — a flaky/empty LLM response degrades to the deterministic
/// source-only receipt, it never throws into the recovery flow.
final class GeminiCaptionVenueExtractor: SocialCaptionVenueExtractor {
    private let geminiTransport: SAVEGeminiTransport
    /// Caption text is bounded before it reaches the prompt: a venue name lives
    /// in the first lines, and a multi-thousand-char caption only burns tokens.
    private let maxCaptionLength = 1_200

    init(
        apiKey: String? = nil,
        modelFallbacks: [String] = SAVEProductionConfig.defaultGeminiModelFallbacks,
        session: URLSession = .shared
    ) {
        self.geminiTransport = SAVEGeminiTransport(
            modelFallbacks: modelFallbacks,
            session: session,
            accessTokenProvider: { try await PrivyAuthService.shared.accessToken() },
            // App Review demo: caption extraction reaches the LLM proxy via an
            // anonymous guest token when there's no real Privy JWT.
            guestTokenProvider: { ReviewDemoGuestTokenHolder.shared.current },
            directAPIKey: apiKey ?? SAVEProductionConfig.clientGeminiAPIKeyIfAllowed(),
            // Tighter than the drawer answer transport: caption extraction is a
            // best-effort fallback on the latency-sensitive paste path.
            requestTimeout: 12,
            maxAttemptsPerModel: 1
        )
    }

    /// Returns the live extractor only when a usable LLM path is configured
    /// (backend proxy URL or a direct API key). Otherwise `nil`, so the service
    /// keeps its deterministic-only behavior without any failed network calls.
    static func liveFromConfig() -> GeminiCaptionVenueExtractor? {
        let hasBackend = SAVEProductionConfig.URLConfigValue(for: ["SAVE_API_URL", "WANDERLY_API_URL"]) != nil
        let apiKey = SAVEProductionConfig.clientGeminiAPIKeyIfAllowed()
        guard hasBackend || apiKey != nil else { return nil }
        return GeminiCaptionVenueExtractor(apiKey: apiKey)
    }

    func extractVenue(caption: String, sourceURL: String) async -> ExtractedVenue? {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let boundedCaption = String(trimmed.prefix(maxCaptionLength))

        let prompt = Self.extractionPrompt(caption: boundedCaption)
        do {
            let text = try await generateText(prompt: prompt, temperature: 0, maxOutputTokens: 256)
            return Self.parseExtraction(from: text)
        } catch {
            // Fail safe: any transport/parse error degrades to the deterministic
            // source-only path. The LLM is a bonus, never a dependency.
            return nil
        }
    }

    static func extractionPrompt(caption: String) -> String {
        """
        From this social caption, extract the ONE primary place the post is about.
        Respond ONLY with strict JSON. No markdown. No text outside the JSON object.

        Rules:
        - name: the venue's proper name, exactly as it literally appears in the caption.
        - The name MUST be text that literally appears in the caption (do not translate, normalize, or invent it).
        - NEVER return a @username/handle or a #hashtag as the name. If the only thing naming the place is a @handle, return the venue's real proper name if the caption states it, otherwise {"name": null}.
        - Prefer the place's real name over the name of a larger campus/area it sits inside (e.g. a specific viewpoint over the whole university).
        - area: the city, neighborhood, or country the place is in, if the caption names one; otherwise null.
        - category: one of cafe, food, bar, hotel, attraction, shopping, stay — your best guess for this place.
        - confidence: a number from 0 to 1 for how sure you are this is a real, specific named venue.
        - The caption may be in any language (English, Spanish, Chinese, etc.). Read it natively.
        - If the caption names NO specific venue (only generic vibes, feelings, or hashtags), return {"name": null}.

        Output schema:
        {"name": "string or null", "area": "string or null", "category": "string or null", "confidence": 0.0}

        Caption:
        \(caption)
        """
    }

    /// Parses the strict-JSON extraction. A missing/null/empty name means "no
    /// venue" → nil. Tolerant of the LLM wrapping JSON in prose by scanning for
    /// the outermost object.
    static func parseExtraction(from text: String) -> ExtractedVenue? {
        let jsonString = extractJSONObject(from: text)
        guard let data = jsonString.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        guard let rawName = object["name"] as? String else { return nil }
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        // The model is instructed to return null/"" for no-venue; null decodes
        // to a missing String, "" trims to empty — both mean "no venue".
        guard !name.isEmpty, name.lowercased() != "null" else { return nil }

        let area = (object["area"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = (object["category"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let confidence: Double
        if let value = object["confidence"] as? Double {
            confidence = value
        } else if let value = object["confidence"] as? Int {
            confidence = Double(value)
        } else if let value = object["confidence"] as? String, let parsed = Double(value) {
            confidence = parsed
        } else {
            confidence = 0.5
        }

        return ExtractedVenue(
            name: name,
            area: (area?.isEmpty == false && area?.lowercased() != "null") ? area : nil,
            category: (category?.isEmpty == false && category?.lowercased() != "null") ? category : nil,
            confidence: min(max(confidence, 0), 1)
        )
    }

    private func generateText(prompt: String, temperature: Double, maxOutputTokens: Int) async throws -> String {
        let body: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": prompt]]]],
            "generationConfig": ["temperature": temperature, "maxOutputTokens": maxOutputTokens]
        ]
        let json = try await geminiTransport.generateContent(body: body)
        guard let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw SAVEGeminiTransportError.emptyResponse
        }
        return text
    }

    private static func extractJSONObject(from text: String) -> String {
        guard let start = text.range(of: "{"),
              let end = text.range(of: "}", options: .backwards),
              start.lowerBound < end.upperBound else {
            return text
        }
        return String(text[start.lowerBound..<end.upperBound])
    }
}
