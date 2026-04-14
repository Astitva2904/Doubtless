import Foundation
import Supabase

// MARK: - Activity Tab Queries
extension SupabaseManager {

    // ──────────────────────────────────────────────
    // MARK: Solver Stats
    // ──────────────────────────────────────────────

    func fetchSolverStats(solverName: String) async throws -> SolverStats {

        // 1. Solved today
        let (todayStart, todayEnd) = Self.todayDateRangeISO()

        var solvedToday = 0
        do {
            let solvedResp = try await client
                .from("doubts")
                .select("id", head: false, count: .exact)
                .eq("solver_name", value: solverName)
                .eq("status", value: "completed")
                .gte("created_at", value: todayStart)
                .lte("created_at", value: todayEnd)
                .execute()
            solvedToday = solvedResp.count ?? 0
        } catch {
            print("fetchSolverStats solvedToday error:", error)
        }

        // 2. Average rating
        var avgRating: Double = 0
        do {
            let ratingResp = try await client
                .from("feedbacks")
                .select("rating")
                .eq("solver_name", value: solverName)
                .execute()

            let ratings = (try? JSONSerialization.jsonObject(with: ratingResp.data) as? [[String: Any]]) ?? []
            if !ratings.isEmpty {
                let total = ratings.compactMap { $0["rating"] as? Double ?? ($0["rating"] as? Int).map { Double($0) } }.reduce(0, +)
                avgRating = total / Double(ratings.count)
            }
        } catch {
            print("fetchSolverStats avgRating error:", error)
        }

        // 3. Total solved (all time)
        var totalSolved = 0
        do {
            let totalResp = try await client
                .from("doubts")
                .select("id", head: false, count: .exact)
                .eq("solver_name", value: solverName)
                .or("status.eq.completed,status.eq.solved")
                .execute()
            totalSolved = totalResp.count ?? 0
        } catch {
            print("fetchSolverStats totalSolved error:", error)
        }

        return SolverStats(solvedToday: solvedToday, averageRating: avgRating, totalSolved: totalSolved)
    }

    // ──────────────────────────────────────────────
    // MARK: Solver Recent Activity
    // ──────────────────────────────────────────────

    func fetchSolverRecentActivity(solverName: String, limit: Int = 20) async throws -> [SolverActivityItem] {

        // Fetch solved/completed doubts
        guard let doubtsResp = try? await client
            .from("doubts")
            .select()
            .eq("solver_name", value: solverName)
            .or("status.eq.completed,status.eq.solved")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute(),
              let doubtsArr = try? JSONSerialization.jsonObject(with: doubtsResp.data) as? [[String: Any]] else {
            return []
        }

        // Fetch all feedbacks for this solver
        var fbMap: [String: [String: Any]] = [:]
        do {
            let fbResp = try await client
                .from("feedbacks")
                .select()
                .eq("solver_name", value: solverName)
                .execute()

            let fbArr = (try? JSONSerialization.jsonObject(with: fbResp.data) as? [[String: Any]]) ?? []
            // Index by doubt_id for fast lookup
            for fb in fbArr {
                if let did = fb["doubt_id"] as? String {
                    fbMap[did] = fb
                }
            }
        } catch {
            print("fetchSolverRecentActivity feedback error:", error)
        }

        var items: [SolverActivityItem] = []
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for d in doubtsArr {
            let subject = d["subject"] as? String ?? "Unknown"
            let createdStr = d["created_at"] as? String ?? ""
            var solvedDate = Date()
            if let parsed = df.date(from: createdStr) {
                solvedDate = parsed
            } else {
                df.formatOptions = [.withInternetDateTime]
                if let parsed2 = df.date(from: createdStr) { solvedDate = parsed2 }
                df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            }

            let doubtId = d["id"] as? String ?? ""
            let fb = fbMap[doubtId]
            let rating = fb?["rating"] as? Double ?? (fb?["rating"] as? Int).map { Double($0) }
            let fbText = fb?["comments"] as? String

            items.append(SolverActivityItem(
                subject: subject,
                solvedAt: solvedDate,
                rating: rating,
                feedbackText: fbText
            ))
        }

        return items
    }

    // ──────────────────────────────────────────────
    // MARK: Leaderboard
    // ──────────────────────────────────────────────

    func fetchLeaderboard(todayOnly: Bool, currentSolverName: String, limit: Int = 10) async throws -> [LeaderboardEntry] {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6Ym9hYWxmaWJ0dGt5ZGJ1YmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MDgxNTUsImV4cCI6MjA4ODM4NDE1NX0.2ITpt_ECAGfhkWca10_oRuKqY-nKBQ-XevW4He4Z8_A"
        var components = URLComponents(string: "https://lzboaalfibttkydbubes.supabase.co/rest/v1/doubts")!
        var qi = [
            URLQueryItem(name: "select", value: "solver_name,solver_image_url"),
            URLQueryItem(name: "or", value: "(status.eq.completed,status.eq.solved)")
        ]
        
        if todayOnly {
            let (todayStart, todayEnd) = Self.todayDateRangeISO()
            qi.append(URLQueryItem(name: "created_at", value: "gte.\(todayStart)"))
            qi.append(URLQueryItem(name: "created_at", value: "lte.\(todayEnd)"))
        }
        components.queryItems = qi
        
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return []
            }

            var countMap: [String: Int] = [:]
            var imageMap: [String: String] = [:]
            for row in rows {
                if let name = row["solver_name"] as? String, !name.isEmpty {
                    countMap[name, default: 0] += 1
                    if let imageURL = row["solver_image_url"] as? String, !imageURL.isEmpty {
                        imageMap[name] = imageURL
                    }
                }
            }

            let sorted = countMap.sorted { $0.value > $1.value }.prefix(limit)
            var entries: [LeaderboardEntry] = []
            for (i, kv) in sorted.enumerated() {
                entries.append(LeaderboardEntry(
                    rank: i + 1,
                    solverName: kv.key,
                    profileImageURL: imageMap[kv.key],
                    doubtsSolved: kv.value,
                    isCurrentUser: kv.key == currentSolverName
                ))
            }
            return entries
        } catch {
            print("fetchLeaderboard error:", error)
            return []
        }
    }

    // ──────────────────────────────────────────────
    // MARK: Student Stats
    // ──────────────────────────────────────────────

    func fetchStudentStats(studentName: String) async throws -> StudentStats {

        // All doubts
        let allResp = try await client
            .from("doubts")
            .select("id, status", head: false, count: .exact)
            .eq("student_name", value: studentName)
            .execute()

        let allDoubts = allResp.count ?? 0

        // Resolved
        let resolvedResp = try await client
            .from("doubts")
            .select("id", head: false, count: .exact)
            .eq("student_name", value: studentName)
            .or("status.eq.completed,status.eq.solved")
            .execute()

        let resolved = resolvedResp.count ?? 0

        // Avg rating from feedbacks where this student gave feedback
        let fbResp = try await client
            .from("feedbacks")
            .select("rating")
            .eq("student_id", value: (try await client.auth.session.user.id.uuidString))
            .execute()

        let fbArr = (try? JSONSerialization.jsonObject(with: fbResp.data) as? [[String: Any]]) ?? []
        var avgRating: Double = 0.0
        if !fbArr.isEmpty {
            let total = fbArr.compactMap { $0["rating"] as? Double ?? ($0["rating"] as? Int).map { Double($0) } }.reduce(0, +)
            avgRating = total / Double(fbArr.count)
        }

        return StudentStats(doubtsAsked: allDoubts, resolved: resolved, averageRating: avgRating)
    }

    // ──────────────────────────────────────────────
    // MARK: Student Doubts (with filter)
    // ──────────────────────────────────────────────

    func fetchStudentDoubts(studentName: String, statusFilter: String? = nil, limit: Int = 30) async throws -> [StudentDoubtItem] {

        var query = client
            .from("doubts")
            .select()
            .eq("student_name", value: studentName)

        if let filter = statusFilter {
            if filter == "solved" {
                query = query.or("status.eq.completed,status.eq.solved")
            } else {
                query = query.eq("status", value: filter)
            }
        }

        let resp = try await query
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        guard let rows = try? JSONSerialization.jsonObject(with: resp.data) as? [[String: Any]] else {
            return []
        }

        // Fetch feedbacks for these doubt IDs
        let doubtIds = rows.compactMap { $0["id"] as? String }
        var fbMap: [String: Double] = [:]
        if !doubtIds.isEmpty {
            let fbResp = try await client
                .from("feedbacks")
                .select("doubt_id, rating")
                .in("doubt_id", values: doubtIds)
                .execute()

            if let fbArr = try? JSONSerialization.jsonObject(with: fbResp.data) as? [[String: Any]] {
                for fb in fbArr {
                    if let did = fb["doubt_id"] as? String,
                       let r = fb["rating"] as? Double ?? (fb["rating"] as? Int).map({ Double($0) }) {
                        fbMap[did] = r
                    }
                }
            }
        }

        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var items: [StudentDoubtItem] = []
        for row in rows {
            let id = UUID(uuidString: (row["id"] as? String ?? "")) ?? UUID()
            let subject = row["subject"] as? String ?? "Unknown"
            let desc = row["description"] as? String ?? ""
            let solver = row["solver_name"] as? String
            let solverInst = row["solver_institute"] as? String
            let status = row["status"] as? String ?? "pending"
            let createdStr = row["created_at"] as? String ?? ""
            var createdDate = Date()
            if let parsed = df.date(from: createdStr) {
                createdDate = parsed
            } else {
                df.formatOptions = [.withInternetDateTime]
                if let p2 = df.date(from: createdStr) { createdDate = p2 }
                df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            }

            let rating = fbMap[row["id"] as? String ?? ""]

            items.append(StudentDoubtItem(
                id: id,
                subject: subject,
                descriptionText: desc,
                solverName: solver,
                solverInstitute: solverInst,
                status: status,
                rating: rating,
                createdAt: createdDate
            ))
        }

        return items
    }

    // ──────────────────────────────────────────────
    // MARK: Top Solvers (for student view)
    // ──────────────────────────────────────────────

    func fetchTopSolvers(limit: Int = 5, sinceDate: Date? = nil) async throws -> [TopSolverEntry] {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6Ym9hYWxmaWJ0dGt5ZGJ1YmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MDgxNTUsImV4cCI6MjA4ODM4NDE1NX0.2ITpt_ECAGfhkWca10_oRuKqY-nKBQ-XevW4He4Z8_A"
        var components = URLComponents(string: "https://lzboaalfibttkydbubes.supabase.co/rest/v1/feedbacks")!
        var qi = [
            URLQueryItem(name: "select", value: "solver_name,rating,created_at")
        ]
        
        if let since = sinceDate {
            let df = ISO8601DateFormatter()
            let sinceStr = df.string(from: since)
            qi.append(URLQueryItem(name: "created_at", value: "gte.\(sinceStr)"))
        }
        components.queryItems = qi
        
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        // Aggregate: solver_name -> [ratings]
        var ratingMap: [String: [Double]] = [:]
        for row in rows {
            guard let name = row["solver_name"] as? String, !name.isEmpty else { continue }
            let r = (row["rating"] as? Double) ?? (row["rating"] as? Int).map({ Double($0) }) ?? 0
            ratingMap[name, default: []].append(r)
        }

        let sorted = ratingMap.map { (name: $0.key, avg: $0.value.reduce(0, +) / Double($0.value.count)) }
            .sorted { $0.avg > $1.avg }
            .prefix(limit)

        var entries: [TopSolverEntry] = []
        for (i, kv) in sorted.enumerated() {
            entries.append(TopSolverEntry(rank: i + 1, solverName: kv.name, averageRating: kv.avg))
        }
        return entries
    }

    // ──────────────────────────────────────────────
    // MARK: Top Students (for student activity view)
    // ──────────────────────────────────────────────

    func fetchTopStudents(limit: Int = 5, sinceDate: Date? = nil) async throws -> [TopStudentEntry] {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6Ym9hYWxmaWJ0dGt5ZGJ1YmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MDgxNTUsImV4cCI6MjA4ODM4NDE1NX0.2ITpt_ECAGfhkWca10_oRuKqY-nKBQ-XevW4He4Z8_A"
        var components = URLComponents(string: "https://lzboaalfibttkydbubes.supabase.co/rest/v1/doubts")!
        var qi = [
            URLQueryItem(name: "select", value: "student_name,student_image_url"),
            URLQueryItem(name: "or", value: "(status.eq.completed,status.eq.solved)")
        ]
        
        if let since = sinceDate {
            let df = ISO8601DateFormatter()
            let sinceStr = df.string(from: since)
            qi.append(URLQueryItem(name: "created_at", value: "gte.\(sinceStr)"))
        }
        
        components.queryItems = qi
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        // Aggregate: student_name -> (count, imageURL)
        var countMap: [String: Int] = [:]
        var imageMap: [String: String] = [:]
        for row in rows {
            guard let name = row["student_name"] as? String, !name.isEmpty else { continue }
            countMap[name, default: 0] += 1
            if let imgUrl = row["student_image_url"] as? String, !imgUrl.isEmpty {
                imageMap[name] = imgUrl
            }
        }

        let sorted = countMap.sorted { $0.value > $1.value }.prefix(limit)
        var entries: [TopStudentEntry] = []
        for (i, kv) in sorted.enumerated() {
            entries.append(TopStudentEntry(
                rank: i + 1,
                studentName: kv.key,
                profileImageURL: imageMap[kv.key],
                doubtsSolved: kv.value
            ))
        }
        return entries
    }

    // ──────────────────────────────────────────────
    // MARK: Helper
    // ──────────────────────────────────────────────

    private static func todayDateRangeISO() -> (String, String) {
        var cal = Calendar.current
        cal.timeZone = .current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(bySettingHour: 23, minute: 59, second: 59, of: start) ?? start
        
        let df = ISO8601DateFormatter()
        return (df.string(from: start), df.string(from: end))
    }
}
