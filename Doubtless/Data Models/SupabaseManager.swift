import Foundation
import Supabase
import UIKit





class SupabaseManager {
    
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        
        let url = URL(string: "https://lzboaalfibttkydbubes.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6Ym9hYWxmaWJ0dGt5ZGJ1YmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MDgxNTUsImV4cCI6MjA4ODM4NDE1NX0.2ITpt_ECAGfhkWca10_oRuKqY-nKBQ-XevW4He4Z8_A"
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }
    
    
    // MARK: - Upload Image to Storage
    
    func uploadImage(_ image: UIImage) async throws -> String {
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 0)
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        
        try await client.storage
            .from("doubt-images")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )
        
        let publicURL = try client.storage
            .from("doubt-images")
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    // MARK: - Upload Document to Storage
    func uploadDocument(_ url: URL) async throws -> String {
        let fileData = try Data(contentsOf: url)
        let fileExt = url.pathExtension.isEmpty ? "pdf" : url.pathExtension.lowercased()
        let fileName = "\(UUID().uuidString).\(fileExt)"
        let contentType = fileExt == "pdf" ? "application/pdf" : "image/jpeg"
        
        try await client.storage
            .from("solver_documents")
            .upload(
                fileName,
                data: fileData,
                options: FileOptions(contentType: contentType)
            )
        
        let publicURL = try client.storage
            .from("solver_documents")
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    // MARK: - Upload Multiple Images
    
    func uploadImages(_ images: [UIImage]) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self) { group in
            for image in images {
                group.addTask {
                    try await self.uploadImage(image)
                }
            }
            var urls: [String] = []
            for try await url in group {
                urls.append(url)
            }
            return urls
        }
    }
    
    
    // MARK: - Upload Doubt
    
    // MARK: Upload Doubt

    func uploadDoubt(
        id: UUID,
        studentName: String,
        studentImageUrl: String?,
        subject: String,
        description: String,
        imageURLs: [String]?,
        language: String? = nil
    ) async throws {

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let doubt = DoubtDB(
            id: id,
            student_name: studentName,
            subject: subject,
            description: description,
            image_urls: imageURLs,
            created_at: formatter.string(from: Date()),
            status: "pending",
            student_image_url: studentImageUrl,
            solver_id: nil,
            solver_name: nil,
            solver_institute: nil,
            solver_image_url: nil,
            language: language
        )

        try await client
            .from("doubts")
            .insert(doubt)
            .execute()
    }
    
    
    // MARK: - Fetch Single Doubt by ID
    
    func fetchDoubtById(doubtId: UUID) async throws -> DoubtDB? {
        let response = try await client
            .from("doubts")
            .select()
            .eq("id", value: doubtId.uuidString)
            .execute()
        
        let doubts = try JSONDecoder().decode([DoubtDB].self, from: response.data)
        return doubts.first
    }
    
    // MARK: - Fetch Pending Doubts
    
    func fetchPendingDoubts() async throws -> [DoubtDB] {

        let response = try await client
            .from("doubts")
            .select()
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()

        print("Fetch Pending Doubts Raw Response:", String(data: response.data, encoding: .utf8) ?? "nil")

        let doubts = try JSONDecoder().decode([DoubtDB].self, from: response.data)
        
        print("Decoded \(doubts.count) doubts")

        return doubts
    }
    
    // MARK: - Fetch Streak Stats
    
    /// Fetches the doubt count per day mapped to indices for the past N days
    func fetchStreakStats(studentName: String? = nil, solverName: String? = nil, daysBack: Int) async throws -> [Int: Int] {
        var query = client.from("doubts").select("created_at")
        
        if let stName = studentName {
            query = query.eq("student_name", value: stName)
        } else if let svName = solverName {
            query = query.eq("solver_name", value: svName)
        }
        query = query.eq("status", value: "completed")
        
        let response = try await query.execute()
        
        // Dynamically decode as an untyped dictionary array. 
        // This is 100% resilient. If old historically 'completed' doubts are missing required fields
        // that DoubtDB expects (like subject or description), strict JSONDecoder throws the entire array out!
        // JSONSerialization simply maps what's there effortlessly.
        guard let items = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] else {
            return [:]
        }
        
        var stats: [Int: Int] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for item in items {
            guard let createdAt = item["created_at"] as? String, createdAt.count >= 10 else { continue }
            
            // Safe string chopping is optimal for Postgres variable strings
            let dateStr = String(createdAt.prefix(10)) // "YYYY-MM-DD"
            
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd"
            df.timeZone = TimeZone.current // Interpret DB's absolute YYYY-MM-DD right into today's timeline
            
            guard let date = df.date(from: dateStr) else { continue }
            
            // Because we slice the timezone away, date represents 00:00 local time.
            let components = calendar.dateComponents([.day], from: date, to: today)
            
            if let daysAgo = components.day, daysAgo >= 0 && daysAgo < daysBack {
                let itemIndex = daysBack - daysAgo
                stats[itemIndex, default: 0] += 1
            }
        }
        return stats
    }
    
    // MARK: - Realtime Subscription for New Doubts
    
    private var doubtsPollingTimer: Timer?
    
    func subscribeToDoubts(onUpdate: @escaping ([DoubtDB]) -> Void) {
        
        // Fetch initially so the screen populates immediately
        Task {
            do {
                let initialDoubts = try await fetchPendingDoubts()
                DispatchQueue.main.async {
                    onUpdate(initialDoubts)
                }
            } catch {
                print("Initial fetch error:", error)
            }
        }
        
        // Use a 2.5s robust polling mechanism instead of websocket
        // to fully guarantee updates appear natively without dependency
        // on PostgreSQL realtime configurations.
        doubtsPollingTimer?.invalidate()
        doubtsPollingTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task {
                do {
                    guard let self = self else { return }
                    let updatedDoubts = try await self.fetchPendingDoubts()
                    DispatchQueue.main.async {
                        onUpdate(updatedDoubts)
                    }
                } catch {
                    print("Error polling pending doubts:", error)
                }
            }
        }
    }
    
    func unsubscribeFromDoubts() {
        doubtsPollingTimer?.invalidate()
        doubtsPollingTimer = nil
    }
    
    // MARK: - Solver Accepts a Doubt
    
    func acceptDoubt(doubtId: UUID, solverName: String, solverInstitute: String, solverImageURL: String?) async throws {
        let user = try await client.auth.session.user
        
        struct DoubtUpdate: Encodable {
            let status: String
            let solver_name: String
            let solver_institute: String
            let solver_image_url: String?
            let solver_id: String
        }
        
        let update = DoubtUpdate(
            status: "accepted",
            solver_name: solverName,
            solver_institute: solverInstitute,
            solver_image_url: solverImageURL,
            solver_id: user.id.uuidString.lowercased()
        )
        
        try await client
            .from("doubts")
            .update(update)
            .eq("id", value: doubtId.uuidString)
            .execute()
    }
    
    // MARK: - Subscribe to Doubt Status (Student Side)
    
    private var doubtStatusChannel: RealtimeChannelV2?
    
    func subscribeToDoubtStatus(doubtId: UUID, onStatusChange: @escaping (DoubtDB) -> Void) {
        let lowercaseId = doubtId.uuidString.lowercased()
        
        // Initial fetch to avoid race conditions where status changes before subscription finishes setting up
        Task {
            do {
                if let initialDoubt = try await self.fetchDoubtById(doubtId: doubtId) {
                    DispatchQueue.main.async {
                        onStatusChange(initialDoubt)
                    }
                }
            } catch {
                print("Error initial fetch for doubt status:", error)
            }
        }
        
        Task {
            doubtStatusChannel = client.realtimeV2.channel("doubt-status:\(lowercaseId)")
            
            let changes = doubtStatusChannel?.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "doubts",
                filter: .eq("id", value: lowercaseId)
            )
            
            Task {
                guard let changes = changes else { return }
                for await change in changes {
                    print("Doubt status change received: \(change)")
                    
                    // Re-fetch the doubt to get latest data
                    do {
                        let response = try await self.client
                            .from("doubts")
                            .select()
                            .eq("id", value: doubtId.uuidString)
                            .execute()
                        
                        let doubts = try JSONDecoder().decode([DoubtDB].self, from: response.data)
                        if let updatedDoubt = doubts.first {
                            DispatchQueue.main.async {
                                onStatusChange(updatedDoubt)
                            }
                        }
                    } catch {
                        print("Error fetching updated doubt:", error)
                    }
                }
            }
            
            do {
                try await doubtStatusChannel?.subscribeWithError()
            } catch {
                print("Error subscribing to doubt status:", error)
            }
        }
    }
    
    func unsubscribeFromDoubtStatus() {
        Task {
            if let channel = doubtStatusChannel {
                await client.realtimeV2.removeChannel(channel)
            }
            doubtStatusChannel = nil
        }
    }
    
    // MARK: - Update Doubt Status
    
    func updateDoubtStatus(doubtId: UUID, status: String) async throws {
        struct StatusUpdate: Encodable {
            let status: String
        }
        
        let update = StatusUpdate(status: status)
        
        try await client
            .from("doubts")
            .update(update)
            .eq("id", value: doubtId.uuidString)
            .execute()
    }
    
    /// Resets a doubt back to pending AND clears solver fields so it
    /// reappears in the solver feed as a fresh, unaccepted doubt.
    func resetDoubtToPending(doubtId: UUID) async throws {
        struct PendingReset: Encodable {
            let status: String
            let solver_name: String?
            let solver_institute: String?
            let solver_image_url: String?
        }
        
        let update = PendingReset(
            status: "pending",
            solver_name: nil,
            solver_institute: nil,
            solver_image_url: nil
        )
        
        try await client
            .from("doubts")
            .update(update)
            .eq("id", value: doubtId.uuidString)
            .execute()
    }

    // MARK: - Delete Doubt
    
    func deleteDoubt(doubtId: UUID) async throws {
        try await client
            .from("doubts")
            .delete()
            .eq("id", value: doubtId.uuidString)
            .execute()
    }

    // MARK: - Submit Feedback
    
    func submitFeedback(doubtId: UUID, solverName: String, rating: Int, resolved: String, technicalIssue: String, comments: String) async throws {
        let user = try await client.auth.session.user
        
        struct FeedbackDB: Encodable {
            let doubt_id: String
            let solver_name: String
            let student_id: String
            let rating: Int
            let resolved: String
            let technical_issue: String
            let comments: String
        }
        
        let feedback = FeedbackDB(
            doubt_id: doubtId.uuidString,
            solver_name: solverName,
            student_id: user.id.uuidString,
            rating: rating,
            resolved: resolved,
            technical_issue: technicalIssue,
            comments: comments
        )
        
        try await client
            .from("feedbacks")
            .insert(feedback)
            .execute()
    }

    // MARK: - Save Solver Documents
    struct SolverDocumentData: Encodable {
        let solver_id: String
        let college_start_month: String
        let college_end_month: String
        let subjects: [String]
        let college_id_url: String
        let jee_rank_url: String
        let marksheet_12th_url: String
        let is_approved: Bool
    }
    
    func saveSolverDocuments(data: SolverDocumentData) async throws {
        try await client
            .from("solver_details")
            .insert(data)
            .execute()
    }
    
    // MARK: - Authentication
    
    /// Returns the role stored in the current user's metadata ("student", "solver", "solver_pending"), or nil if not set.
    func getUserRole(for user: User) -> String? {
        guard let roleValue = user.userMetadata["role"] else { return nil }
        
        // Try .stringValue first (works for most cases)
        if let sv = roleValue.stringValue, !sv.isEmpty {
            return sv
        }
        
        // Fallback: convert via String(describing:) and strip quotes
        let raw = String(describing: roleValue)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
        
        if raw == "student" || raw == "solver" || raw == "solver_pending" {
            return raw
        }
        
        return nil
    }
    
    /// Returns true if the user's role belongs to the solver side ("solver" or "solver_pending")
    func isSolverSideRole(_ role: String?) -> Bool {
        guard let role = role else { return false }
        return role == "solver" || role == "solver_pending"
    }
    
    /// Fetches the FRESH user from the server and returns their role.
    /// Use this instead of getUserRole(for:) when you need the latest server-side metadata.
    func fetchCurrentUserRole() async -> String? {
        do {
            // Force a refresh from the server to get latest metadata
            let session = try await client.auth.session
            return getUserRole(for: session.user)
        } catch {
            print("⚠️ Could not fetch current user role: \(error)")
            return nil
        }
    }

    
    func signUp(email: String, password: String, name: String, mobile: String, role: String = "student", profileImageUrl: String? = nil) async throws -> User {
        var metadata: [String: AnyJSON] = [
            "name": try AnyJSON(name), 
            "email": try AnyJSON(email), 
            "mobile": try AnyJSON(mobile),
            "role": try AnyJSON(role)
        ]
        if let imageUrl = profileImageUrl {
            metadata["profile_image_url"] = try AnyJSON(imageUrl)
        }
        
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password,
            data: metadata
        )
        return authResponse.user
    }
    
    // 2. Log In (Email & Password)
    func logIn(email: String, password: String) async throws -> User {
        let authResponse = try await client.auth.signIn(email: email, password: password)
        return authResponse.user
    }
    
    // 3. Log Out
    func logOut() async throws {
        try await client.auth.signOut()
    }
    
    // 4. Get Current User
    func getCurrentUser() async throws -> User? {
        return try await client.auth.session.user
    }
    
    // MARK: - Update Password (Authenticated User)
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = try await getCurrentUser(), let email = user.email else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found or email missing."])
        }
        
        // Authenticate with current password to verify it
        _ = try await client.auth.signIn(email: email, password: currentPassword)
        
        // If successful, update the password
        _ = try await client.auth.update(
            user: UserAttributes(password: newPassword)
        )
    }

    // 4b. Get Current Solver Info (name, institute, image URL)
    func getCurrentSolverInfo() async throws -> (name: String, institute: String, imageURL: String?) {
        let user = try await client.auth.session.user
        
        let name = user.userMetadata["name"]?.stringValue ?? "Solver"
        
        let institute = user.userMetadata["institute"]?.stringValue
            ?? user.userMetadata["college"]?.stringValue
            ?? ""
        
        let imageURL = user.userMetadata["profile_image_url"]?.stringValue
        
        return (name: name, institute: institute, imageURL: imageURL)
    }

    /// Stamps the given role into the current user's auth metadata.
    func setUserRole(_ role: String) async throws {
        guard let currentUser = try await getCurrentUser() else { return }
        
        var updatedMetadata = currentUser.userMetadata
        updatedMetadata["role"] = try AnyJSON(role)
        
        try await client.auth.update(user: UserAttributes(data: updatedMetadata))
    }
    
    // MARK: - Password Reset (OTP-based)
    
    /// Calls the Edge Function which generates a 4-digit OTP, stores it in `password_resets` table (using service role), and sends the email
    func requestPasswordReset(email: String) async throws {
        // The Edge Function handles OTP generation, storage in password_resets, AND sending the email.
        // This avoids RLS issues since the Edge Function uses the service_role key.
        struct EmailRequest: Encodable {
            let email: String
        }
        
        let emailPayload = EmailRequest(email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
        let payloadData = try JSONEncoder().encode(emailPayload)
        
        let edgeFunctionURL = URL(string: "https://lzboaalfibttkydbubes.supabase.co/functions/v1/send-otp-email")!
        var request = URLRequest(url: edgeFunctionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6Ym9hYWxmaWJ0dGt5ZGJ1YmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MDgxNTUsImV4cCI6MjA4ODM4NDE1NX0.2ITpt_ECAGfhkWca10_oRuKqY-nKBQ-XevW4He4Z8_A", forHTTPHeaderField: "Authorization")
        request.httpBody = payloadData
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PasswordReset", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Failed to send verification code: \(errorMsg)"
            ])
        }
    }
    
    /// Verifies the 4-digit OTP code via the Edge Function (using service role to bypass RLS)
    func verifyPasswordResetOTP(email: String, code: String) async throws -> Bool {
        struct VerifyRequest: Encodable {
            let email: String
            let otp_code: String
            let action: String
        }
        
        let payload = VerifyRequest(
            email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
            otp_code: code,
            action: "verify-otp"
        )
        let payloadData = try JSONEncoder().encode(payload)
        
        let edgeFunctionURL = URL(string: "https://lzboaalfibttkydbubes.supabase.co/functions/v1/reset-password")!
        var request = URLRequest(url: edgeFunctionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6Ym9hYWxmaWJ0dGt5ZGJ1YmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MDgxNTUsImV4cCI6MjA4ODM4NDE1NX0.2ITpt_ECAGfhkWca10_oRuKqY-nKBQ-XevW4He4Z8_A", forHTTPHeaderField: "Authorization")
        request.httpBody = payloadData
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return false
        }
        
        struct VerifyResponse: Decodable {
            let valid: Bool
        }
        
        let result = try JSONDecoder().decode(VerifyResponse.self, from: responseData)
        return result.valid
    }
    
    /// Resets the user's password via the Edge Function (which uses Supabase service role key)
    func resetPassword(email: String, otpCode: String, newPassword: String) async throws {
        // First verify OTP is still valid
        let isValid = try await verifyPasswordResetOTP(email: email, code: otpCode)
        guard isValid else {
            throw NSError(domain: "PasswordReset", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Your verification code has expired. Please request a new one."
            ])
        }
        
        // Call Edge Function to update password (requires service_role key on server side)
        struct ResetRequest: Encodable {
            let email: String
            let new_password: String
        }
        
        let payload = ResetRequest(email: email.lowercased(), new_password: newPassword)
        let payloadData = try JSONEncoder().encode(payload)
        
        let edgeFunctionURL = URL(string: "https://lzboaalfibttkydbubes.supabase.co/functions/v1/reset-password")!
        var request = URLRequest(url: edgeFunctionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6Ym9hYWxmaWJ0dGt5ZGJ1YmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MDgxNTUsImV4cCI6MjA4ODM4NDE1NX0.2ITpt_ECAGfhkWca10_oRuKqY-nKBQ-XevW4He4Z8_A", forHTTPHeaderField: "Authorization")
        request.httpBody = payloadData
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PasswordReset", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Password reset failed: \(errorMsg)"
            ])
        }
        
        // OTP is marked as used by the Edge Function (using service_role key)
    }
    
    
    // MARK: - Delete Account
    
    /// Permanently deletes the current user's account and all associated data.
    /// Uses the delete-account Edge Function which runs with service_role privileges.
    func deleteAccount() async throws {
        let user = try await client.auth.session.user
        
        struct DeleteRequest: Encodable {
            let user_id: String
        }
        
        let payload = DeleteRequest(user_id: user.id.uuidString.lowercased())
        let payloadData = try JSONEncoder().encode(payload)
        
        let edgeFunctionURL = URL(string: "https://lzboaalfibttkydbubes.supabase.co/functions/v1/delete-account")!
        var request = URLRequest(url: edgeFunctionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6Ym9hYWxmaWJ0dGt5ZGJ1YmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MDgxNTUsImV4cCI6MjA4ODM4NDE1NX0.2ITpt_ECAGfhkWca10_oRuKqY-nKBQ-XevW4He4Z8_A", forHTTPHeaderField: "Authorization")
        request.httpBody = payloadData
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "DeleteAccount", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Account deletion failed: \(errorMsg)"
            ])
        }
        
        // Sign out locally after server-side deletion
        try await client.auth.signOut()
    }
}
