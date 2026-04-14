import Foundation

struct DoubtDB: Codable {

    let id: UUID
    let student_name: String
    let subject: String
    let description: String
    let image_urls: [String]?
    let created_at: String
    let status: String
    
    // Student Info
    let student_image_url: String?
    
    // Solver info (populated when a solver accepts the doubt)
    let solver_id: String?
    let solver_name: String?
    let solver_institute: String?
    let solver_image_url: String?
    
    // Language of communication chosen by the student
    let language: String?
    
    /// Converts the Supabase ISO 8601 date string to a Date object
    var createdAtDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: created_at) {
            return date
        }
        // Fallback: try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: created_at)
    }
}
