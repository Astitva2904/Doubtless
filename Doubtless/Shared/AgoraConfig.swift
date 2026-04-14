import Foundation

/// Central configuration for Agora Video SDK.
/// Replace the placeholder App ID with your real Agora App ID from https://console.agora.io
struct AgoraConfig {
    
    /// Your Agora App ID (get it from https://console.agora.io)
    /// ⚠️ IMPORTANT: Replace this with your actual Agora App ID before running.
    static let appId = "6bb04af8de7142738819b21520075039"
    
    /// Generates a channel name from a doubt ID so both student and solver
    /// join the same channel automatically.
    static func channelName(for doubtId: UUID) -> String {
        return "doubtless_\(doubtId.uuidString.lowercased())"
    }
    
    /// Temporary token – set to `nil` for testing mode (App ID without certificate).
    /// For production, generate tokens server-side.
    static let token: String? = nil
}
