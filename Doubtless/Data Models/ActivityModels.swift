import Foundation

// MARK: - Solver Activity Models

struct SolverStats {
    let solvedToday: Int
    let averageRating: Double
    let totalSolved: Int
}

struct SolverActivityItem {
    let subject: String
    let solvedAt: Date
    let rating: Double?
    let feedbackText: String?
}

struct LeaderboardEntry {
    let rank: Int
    let solverName: String
    let profileImageURL: String?
    let doubtsSolved: Int
    let isCurrentUser: Bool
}

// MARK: - Student Activity Models

struct StudentStats {
    let doubtsAsked: Int
    let resolved: Int
    let averageRating: Double
}

struct StudentDoubtItem {
    let id: UUID
    let subject: String
    let descriptionText: String
    let solverName: String?
    let solverInstitute: String?
    let status: String
    let rating: Double?
    let createdAt: Date
}

struct TopSolverEntry {
    let rank: Int
    let solverName: String
    let averageRating: Double
}

struct TopStudentEntry {
    let rank: Int
    let studentName: String
    let profileImageURL: String?
    let doubtsSolved: Int
}
