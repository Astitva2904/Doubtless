import UIKit

struct Session {
    let id: Int
    let subject: Subject
    let date: Date

    let solverId: Int              // 🔑 link to Solver
    let imageURLs: [String]        // 📷 uploaded doubt images

    let notes: String
    let duration: String
    let rating: Int
}

enum Subject: String, CaseIterable {
    case physics = "Physics"
    case chemistry = "Chemistry"
    case maths = "Maths"
}
