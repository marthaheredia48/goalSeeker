//
//  User.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.
//

import Foundation
import SwiftUI
import Combine
import UIKit



// MARK: - User Archetype (NUEVO)
enum UserArchetype: String, Codable, CaseIterable {
    case gourmetFoodie = "Gourmet_Foodie"
    case streetFoodFan = "Street_Food_Fan"
    case artHistoryBuff = "Art_History_Buff"
    case nightlifeSeeker = "Nightlife_Seeker"
    case sportsFanatic = "Sports_Fanatic"
    case budgetBackpacker = "Budget_Backpacker"
    case luxuryTraveler = "Luxury_Traveler"
    case familyWithKids = "Family_With_Kids"
    case digitalNomad = "Digital_Nomad"
    case businessTraveler = "Business_Traveler"
    case casualTourist = "Casual_Tourist"
    case localExplorer = "Local_Explorer"
    
    var displayName: String {
        switch self {
        case .gourmetFoodie: return "🍽️ Foodie Gourmet"
        case .streetFoodFan: return "🌮 Fan de Comida Callejera"
        case .artHistoryBuff: return "🎨 Amante del Arte e Historia"
        case .nightlifeSeeker: return "🎉 Buscador de Vida Nocturna"
        case .sportsFanatic: return "⚽ Fanático del Deporte"
        case .budgetBackpacker: return "🎒 Viajero Económico"
        case .luxuryTraveler: return "💎 Viajero de Lujo"
        case .familyWithKids: return "👨‍👩‍👧‍👦 Familia con Niños"
        case .digitalNomad: return "💻 Nómada Digital"
        case .businessTraveler: return "💼 Viajero de Negocios"
        case .casualTourist: return "📸 Turista Casual"
        case .localExplorer: return "🗺️ Explorador Local"
        }
    }
    
    var description: String {
        switch self {
        case .gourmetFoodie:
            return "Buscas restaurantes únicos y experiencias culinarias auténticas"
        case .streetFoodFan:
            return "Te encanta la comida callejera y lugares locales económicos"
        case .artHistoryBuff:
            return "Museos, galerías y sitios históricos son tu pasión"
        case .nightlifeSeeker:
            return "Bares, clubes y entretenimiento nocturno"
        case .sportsFanatic:
            return "Estadios, bares deportivos y eventos en vivo"
        case .budgetBackpacker:
            return "Maximizas experiencias con presupuesto limitado"
        case .luxuryTraveler:
            return "Prefieres lugares exclusivos y servicios premium"
        case .familyWithKids:
            return "Lugares familiares, seguros y divertidos para niños"
        case .digitalNomad:
            return "Cafés con WiFi, espacios de coworking y lugares tranquilos"
        case .businessTraveler:
            return "Eficiencia, lugares cerca de tu hotel y opciones rápidas"
        case .casualTourist:
            return "Balance entre atracciones populares y joyas ocultas"
        case .localExplorer:
            return "Vives aquí y buscas descubrir nuevos lugares constantemente"
        }
    }
    
    var interests: Set<LocationType> {
        switch self {
        case .gourmetFoodie, .streetFoodFan:
            return [.food]
        case .artHistoryBuff:
            return [.cultural, .souvenirs]
        case .nightlifeSeeker:
            return [.entertainment, .food]
        case .sportsFanatic:
            return [.stadium, .entertainment, .food]
        case .budgetBackpacker, .localExplorer:
            return [.food, .cultural, .entertainment, .others]
        case .luxuryTraveler:
            return [.food, .shop, .cultural]
        case .familyWithKids:
            return [.food, .entertainment, .cultural, .others]
        case .digitalNomad:
            return [.food, .cultural, .others]
        case .businessTraveler:
            return [.food, .shop]
        case .casualTourist:
            return [.food, .cultural, .shop, .entertainment]
        }
    }
}

// MARK: - User Model (ACTUALIZADO)
struct User: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let profileImageName: String
    var teamPreference: String
    var opinionOnboardingPlace: Set<LocationType>?
    
    // 🆕 NUEVO: Arquetipo del usuario
    var archetype: UserArchetype?
    
    var points: Int
    var streak: Int
    var completedChallenges: [Challenge]
    var visits: [Visit]
    var cards: [WorldCupCard]?
    
    // NUEVO: Propiedad computada para obtener intereses
    var interests: Set<LocationType> {
        // Prioridad: onboarding preferences > archetype interests > default
        if let onboardingPrefs = opinionOnboardingPlace, !onboardingPrefs.isEmpty {
            return onboardingPrefs
        }
        
        if let archetype = archetype {
            return archetype.interests
        }
        
        // Default: casual tourist interests
        return [.food, .cultural, .shop, .entertainment]
    }
    
    func recentVisits(limit: Int) -> [Visit] {
        return Array(visits.sorted(by: { $0.date > $1.date }).prefix(limit))
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Visit Model (ACTUALIZADO)
struct Visit: Identifiable, Codable {
    let id: UUID
    let location: MapLocation
    let date: Date
    let rating: Int
    let comment: String?
}

// MARK: - Challenge Model (ACTUALIZADO)
struct Challenge: Identifiable, Codable {
    let id: UUID
    let title: String
    var isCompleted: Bool
    let description: String
    let detailedDescription: String
    let pointsAwarded: Int
    var completionDate: Date?
    
    // Nota: UIImage no es Codable, usar Data
    var photoEvidenceData: Data?
    var review: String?
    var rating: Int?
    var recommended: Bool?
    
    var photoEvidence: UIImage? {
        get {
            guard let data = photoEvidenceData else { return nil }
            return UIImage(data: data)
        }
        set {
            photoEvidenceData = newValue?.jpegData(compressionQuality: 0.7)
        }
    }
}



// MARK: - Models (Posts & Community)
struct PostModel: Identifiable {
    let id: UUID
    let user: UserModel
    let businessName: String
    let businessImageName: String
    let text: String
    var likes: Int
    var isLiked: Bool = false
    var comments: [CommentModel]
    let date: Date
    var challengePhoto: UIImage?
    var rating: Int?
    var recommended: Bool?
}

struct UserModel: Identifiable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarName: String
    let country: String
}

struct CommentModel: Identifiable {
    let id: UUID
    let user: UserModel
    let text: String
    let date: Date
}

struct LeaderboardEntry: Identifiable, Hashable {
    let id = UUID()
    let country: String
    var points: Int
    let flagEmoji: String
}

// MARK: - CommunityViewModel (sin cambios necesarios)
final class CommunityViewModel: ObservableObject {
    @Published var posts: [PostModel] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    
    private let currentUser = UserModel(
        id: UUID(),
        username: "ana804",
        displayName: "Ana",
        avatarName: "user_local",
        country: "Mexico"
    )
    
    private var userData: UserDataManager?
    private var hasLoadedSavedPosts = false
    
    init() {
        print("🔵 CommunityViewModel init()")
        loadSampleLeaderboard()
        loadSampleUsersAndPosts()
    }
    
    func connectUserData(_ manager: UserDataManager) {
        print("🔵 connectUserData llamado")
        self.userData = manager
        
        if !hasLoadedSavedPosts {
            loadSavedChallengePosts()
            hasLoadedSavedPosts = true
        }
    }
    
    func updateLeaderboard(for country: String, adding points: Int) {
        if let index = leaderboard.firstIndex(where: { $0.country == country }) {
            leaderboard[index].points += points
            leaderboard.sort { $0.points > $1.points }
        }
    }
    
    private func loadSampleLeaderboard() {
        leaderboard = [
            LeaderboardEntry(country: "México", points: 90, flagEmoji: "🇲🇽"),
            LeaderboardEntry(country: "Argentina", points: 10, flagEmoji: "🇦🇷"),
            LeaderboardEntry(country: "Colombia", points: 45, flagEmoji: "🇨🇴"),
            LeaderboardEntry(country: "Chile", points: 30, flagEmoji: "🇨🇱"),
            LeaderboardEntry(country: "Peru", points: 25, flagEmoji: "🇵🇪"),
            LeaderboardEntry(country: "Spain", points: 60, flagEmoji: "🇪🇸")
        ].sorted { $0.points > $1.points }
    }
    
    private func loadSampleUsersAndPosts() {
        let u1 = UserModel(id: UUID(), username: "maria89", displayName: "María H.", avatarName: "user1", country: "México")
        let u2 = UserModel(id: UUID(), username: "carlos_rs", displayName: "Carlos R.", avatarName: "user2", country: "Argentina")
        
        posts = [
            PostModel(
                id: UUID(),
                user: u1,
                businessName: "Café La Esquina",
                businessImageName: "cafe1",
                text: "Great coffee and cozy atmosphere ☕️🇲🇽",
                likes: 12,
                comments: [
                    CommentModel(id: UUID(), user: u2, text: "Thanks for the tip!", date: Date())
                ],
                date: Date().addingTimeInterval(-3600)
            ),
        ]
        print("📝 Posts de muestra cargados: \(posts.count)")
    }
    
    private func loadSavedChallengePosts() {
        print("🔵 loadSavedChallengePosts() llamado")
        
        guard let userData = userData else {
            print("❌ userData es nil")
            return
        }
        
        print("✅ userData existe, cargando posts...")
        let savedPosts = userData.convertToPostModels()
        print("📂 Posts encontrados: \(savedPosts.count)")
        
        posts.insert(contentsOf: savedPosts, at: 0)
        print("✅ Total posts después de cargar: \(posts.count)")
        
        for (index, post) in posts.enumerated() {
            print("  [\(index)] \(post.businessName) - \(post.date)")
        }
    }
    
    func addChallengePost(
        challengeTitle: String,
        photo: UIImage,
        review: String,
        rating: Int,
        recommended: Bool
    ) {
        print("🔵 addChallengePost() llamado para: \(challengeTitle)")
        
        guard let userData = userData else {
            print("❌ No se puede guardar: UserDataManager no disponible")
            return
        }
        
        userData.saveChallengePost(
            challengeTitle: challengeTitle,
            photo: photo,
            review: review,
            rating: rating,
            recommended: recommended
        )
        
        let newPost = PostModel(
            id: UUID(),
            user: currentUser,
            businessName: challengeTitle,
            businessImageName: "challenge_photo",
            text: review,
            likes: 0,
            comments: [],
            date: Date(),
            challengePhoto: photo,
            rating: rating,
            recommended: recommended
        )
        
        posts.insert(newPost, at: 0)
        print("✅ Post agregado. Total posts: \(posts.count)")
    }
    
    func toggleLike(postId: UUID) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLiked.toggle()
            posts[index].likes += posts[index].isLiked ? 1 : -1
        }
    }
    
    func addComment(postId: UUID, commentText: String, from user: UserModel) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            let comment = CommentModel(id: UUID(), user: user, text: commentText, date: Date())
            posts[index].comments.append(comment)
        }
    }
}
