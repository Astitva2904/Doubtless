import Foundation
import Supabase
import Auth

// MARK: - RPC Models (Sendable)

struct CredBalanceRow: Codable, Sendable {
    let balance: Int
}

struct WelcomeBonusParams: Codable, Sendable {
    let p_user_id: String
}

struct FulfillPurchaseParams: Codable, Sendable {
    let p_user_id: String
    let p_amount: Int
    let p_transaction_id: String
}

struct ProcessSessionParams: Codable, Sendable {
    let p_student_id: String
    let p_solver_id: String
    let p_doubt_id: String
}

struct CredEarningRow: Codable, Sendable {
    // We parse as Double because the SQL column is DECIMAL(10,2) for the 20.40 payouts
    let amount: Double
    let status: String
}

/// Manages the user's credit balance exclusively through secure server-side RPC calls.
/// Never trusts the client for logic or balances.
final class CreditsManager: Sendable {

    static let shared = CreditsManager()
    private init() {}

    // MARK: - Fetch Balance
    func fetchBalance() async throws -> Int {
        let userId = try await currentUserId()

        let response: [CredBalanceRow] = try await SupabaseManager.shared.client
            .from("cred_balances")
            .select("balance")
            .eq("user_id", value: userId)
            .execute()
            .value

        if let first = response.first {
            return first.balance
        }

        // Check and grant welcome bonus using server-safe RPC
        try await SupabaseManager.shared.client
            .rpc("grant_welcome_bonus", params: ["p_user_id": userId])
            .execute()
            
        return 60 // 60 is the welcome bonus hardcoded in SQL
    }

    // MARK: - Check Can Afford Session
    func canAffordSession() async throws -> Bool {
        let balance = try await fetchBalance()
        return balance >= 30
    }

    // MARK: - Add Credits (Purchase)
    func addPurchasedCredits(amount: Int, transactionId: String) async throws {
        let userId = try await currentUserId()
        
        let params: [String: AnyJSON] = [
            "p_user_id": .string(userId),
            "p_amount": .integer(amount),
            "p_transaction_id": .string(transactionId)
        ]
        
        // Let the server securely process the purchase fulfillment
        try await SupabaseManager.shared.client
            .rpc("fulfill_purchase", params: params)
            .execute()
    }

    // MARK: - Process Session
    /// Securely deducts 30 creds from student and grants 20.40 to solver entirely server-side.
    /// Returns `true` if the server successfully processed the deduction (student had funds).
    @discardableResult
    func deductForSession(doubtId: UUID, solverId: String) async throws -> Bool {
        let studentId = try await currentUserId()

        guard !solverId.isEmpty else { return false }
        
        let params: [String: AnyJSON] = [
            "p_student_id": .string(studentId),
            "p_solver_id": .string(solverId),
            "p_doubt_id": .string(doubtId.uuidString)
        ]

        let success: Bool = try await SupabaseManager.shared.client
            .rpc("process_session_deduction", params: params)
            .execute()
            .value
            
        if success {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .creditsDidUpdate, object: nil)
            }
        }
            
        return success
    }

    // MARK: - Fetch Solver Earnings
    /// Returns the total earnings for the current solver as a formatted Double (e.g. 20.40).
    func fetchSolverEarnings() async throws -> (total: Double, pending: Double) {
        let userId = try await currentUserId()

        let response: [CredEarningRow] = try await SupabaseManager.shared.client
            .from("solver_earnings")
            .select("amount, status")
            .eq("solver_id", value: userId)
            .execute()
            .value

        var total: Double = 0
        var pending: Double = 0
        for row in response {
            total += row.amount
            if row.status == "pending" {
                pending += row.amount
            }
        }
        return (total, pending)
    }

    // MARK: - Helpers
    private func currentUserId() async throws -> String {
        let user = try await SupabaseManager.shared.client.auth.session.user
        return user.id.uuidString.lowercased()
    }
}
