//
//  ProfileView.swift
//  fifa2025
//
//  Created by Georgina on 11/10/25.
//



import SwiftUI
import CoreLocation

struct ProfileView: View {
    @EnvironmentObject var userData: UserDataManager
    
    // ✅ NO necesita HomeViewModel, solo el singleton
    private let locationService = SharedLocationService.shared
    @State private var currentLocationName: String = "Centro Histórico"
    
    private var displayVisits: [Visit] {
        if userData.user.visits.isEmpty {
            return getMockedVisits()
        }
        return userData.user.recentVisits(limit: 2)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 5) {
                    ProfileHeaderView(user: userData.user)
                    
                    // ✅ Selector de ubicación en Profile
                   // ProfileLocationPickerSection(
                       // locationService: locationService,
                     //   currentLocationName: $currentLocationName
                 //   )
                    
                    GamificationStatsView(
                        points: userData.user.points,
                        streak: userData.user.streak
                    )
                    
                    CompletedChallengesView(challenges: userData.user.completedChallenges)
                    
                    RecentActivityView(visits: displayVisits)
                }
                .padding()
            }
            .background(Color("BackgroudColor"))
            .onAppear {
                currentLocationName = locationService.currentPreset.name
                print("🔍 Profile: \(userData.user.points) pts, Ubicación: \(currentLocationName)")
            }
            // ✅ Escuchar cambios de ubicación
            .onReceive(locationService.$currentPreset) { newPreset in
                currentLocationName = newPreset.name
            }
        }
    }
    
    private func getMockedVisits() -> [Visit] {
        let mockLocations = [
            MapLocation(
                id: UUID().uuidString,
                denueID: "mock001",
                name: "Tacos El Paisa",
                type: .food,
                coordinate: CLLocationCoordinate2D(latitude: 19.0436, longitude: -98.1986),
                description: "Auténticos tacos al pastor",
                imageName: "taco_place",
                promotesWomenInSports: false,
                address: "Calle 5 de Mayo 123",
                phoneNumber: "222-123-4567",
                website: nil
            ),
            MapLocation(
                id: UUID().uuidString,
                denueID: "mock002",
                name: "Museo Amparo",
                type: .cultural,
                coordinate: CLLocationCoordinate2D(latitude: 19.0414, longitude: -98.1973),
                description: "Arte prehispánico y contemporáneo",
                imageName: "museum",
                promotesWomenInSports: false,
                address: "Calle 2 Sur 708",
                phoneNumber: "222-229-3850",
                website: "www.museoamparo.com"
            )
        ]
        
        return [
            Visit(
                id: UUID(),
                location: mockLocations[0],
                date: Date().addingTimeInterval(-86400 * 2),
                rating: 5,
                comment: "¡Los mejores tacos de la ciudad! Totalmente recomendado 🌮"
            ),
            Visit(
                id: UUID(),
                location: mockLocations[1],
                date: Date().addingTimeInterval(-86400 * 5),
                rating: 4,
                comment: "Increíble colección de arte. Vale la pena visitarlo"
            )
        ]
    }
}

// MARK: - 🆕 Location Picker para Profile
struct ProfileLocationPickerSection: View {
    let locationService: SharedLocationService
    @Binding var currentLocationName: String
    @State private var selectedCategory: SharedLocationService.LocationCategory = .neighborhood
    @State private var showLocationInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header con ubicación actual
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📍 Ubicación de Prueba")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.primaryText)
                    
                    Text("Actual: \(currentLocationName)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.secondaryText)
                }
                
                Spacer()
                
                // Info Button
                Button {
                    showLocationInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                
                // Category Picker
                Menu {
                    ForEach([
                        SharedLocationService.LocationCategory.neighborhood,
                        .commercial,
                        .stadium,
                        .museum,
                        .park
                    ], id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(category.displayName)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCategory.displayName)
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.fifaCompPurple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.fifaCompPurple.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            // Selector de ubicaciones
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SharedLocationService.locations(for: selectedCategory), id: \.self) { location in
                        ProfileLocationButton(
                            location: location,
                            isSelected: location.name == currentLocationName,
                            action: {
                                print("🔄 Profile: Cambiando a \(location.name)")
                                locationService.setLocation(location)
                                currentLocationName = location.name
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Info adicional
            if showLocationInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ℹ️ Modo de Prueba")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("Los cambios de ubicación se reflejan automáticamente en:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.orange)
                            Text("HomeView - Sugerencias de lugares")
                                .font(.system(size: 10))
                        }
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.blue)
                            Text("MapView - Itinerario en mapa")
                                .font(.system(size: 10))
                        }
                    }
                    .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

// MARK: - Botón de Ubicación para Profile
struct ProfileLocationButton: View {
    let location: SharedLocationService.PresetLocation
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(location.emoji)
                    .font(.system(size: 28))
                
                Text(location.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 28)
            }
            .frame(width: 85, height: 75)
            .background(
                isSelected
                    ? Color.fifaCompPurple
                    : Color.secondaryBackground.opacity(0.8)
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? Color.fifaCompPurple.opacity(0.5) : .clear,
                radius: 10
            )
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Subviews Originales (sin cambios)
struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Goal Seeker")
                    .font(.title.weight(.heavy))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 10)
                
                Text("Perfil")
                    .font(Font.theme.largeTitle)
                    .foregroundColor(Color.primaryText)
                    .padding(.top, 1)
                    .padding(.leading, 5)
                
                HStack(alignment: .center) {
                    Image("user_local")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3)))
                        .padding(.trailing, 5)
                    
                    VStack(alignment: .leading) {
                        Text("Ana")
                            .font(Font.theme.largeTitle)
                            .foregroundColor(Color.primaryText)
                        
                        Text("Supporting: \(user.teamPreference)")
                            .foregroundColor(Color.secondaryText)
                        
                        Text("🇲🇽")
                            .font(.system(size: 15))
                    }
                    
                    Spacer()
                }
                .font(Font.theme.subheadline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondaryBackground.opacity(0.5))
                .cornerRadius(16)
            }
            Spacer()
        }
    }
}

struct GamificationStatsView: View {
    let points: Int
    let streak: Int
    
    var body: some View {
        HStack {
            StatCard(title: "Total Points", value: "\(points) pts", icon: "star.fill", color: Color.fifaCompLime)
            StatCard(title: "Current Streak", value: "\(streak) Days", icon: "flame.fill", color: Color.fifaCompRed)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
                Spacer()
            }
            Text(value)
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

struct RecentActivityView: View {
    let visits: [Visit]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)
                .padding(.horizontal)
            
            ForEach(visits) { visit in
                VisitRow(visit: visit)
            }
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

struct VisitRow: View {
    let visit: Visit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(visit.location.name)
                    .font(Font.theme.subheadline)
                    .foregroundColor(Color.primaryText)
                Spacer()
                Text(visit.date, style: .date)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
            }
            
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= visit.rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
            }
            
            if let comment = visit.comment {
                Text("\"\(comment)\"")
                    .font(Font.theme.body)
                    .italic()
                    .foregroundColor(Color.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CompletedChallengesView: View {
    let challenges: [Challenge]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Completed Challenges")
                .font(Font.theme.headline)
                .foregroundColor(Color.primaryText)
                .padding(.horizontal)
            
            ForEach(challenges) { challenge in
                ChallengeRow(challenge: challenge)
            }
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

struct ChallengeRow: View {
    let challenge: Challenge
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(Color.fifaCompGreen)
            
            VStack(alignment: .leading) {
                Text(challenge.title)
                    .font(Font.theme.subheadline)
                    .foregroundColor(Color.primaryText)
                Text(challenge.description)
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
            }
            
            Spacer()
            
            Text("+\(challenge.pointsAwarded) pts")
                .font(Font.theme.subheadline)
                .foregroundColor(Color.fifaCompLime)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserDataManager.shared)  // ✅ Usar .shared
}
