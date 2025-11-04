//
//  HomeView.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.


import SwiftUI
internal import EventKit
// Al final del archivo, agrega:

struct LocationPickerSection: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var selectedCategory: SharedLocationService.LocationCategory = .neighborhood
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🧪 Probar ubicaciones de CDMX")
                    .font(Font.theme.subheadline)
                    .foregroundColor(Color.primaryText)
                
                Spacer()
                
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.fifaCompPurple.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SharedLocationService.locations(for: selectedCategory), id: \.self) { location in
                        LocationTestButton(
                            location: location,
                            viewModel: viewModel
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            
            Text("Las sugerencias cambiarán según la ubicación seleccionada")
                .font(.system(size: 10))
                .foregroundColor(Color.secondaryText.opacity(0.7))
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

struct LocationTestButton: View {
    let location: SharedLocationService.PresetLocation
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            
            viewModel.changeTestLocation(to: location)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isPressed = false
                }
            }
        }) {
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
                isPressed
                    ? Color.fifaCompPurple
                    : Color.secondaryBackground.opacity(0.8)
            )
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: isPressed ? Color.fifaCompPurple.opacity(0.5) : .clear,
                radius: 10
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var communityVM: CommunityViewModel
    @EnvironmentObject var userData: UserDataManager
    
    @State private var showChallengePopup = false
    @State private var selectedChallenge: Challenge?
    @State private var challengeIndexToComplete: Int?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroudColor").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                     
          

                        
                        HeaderGreetingView(name: "Ana")
                        ScoreView(points: userData.user.points)
                        
                   
                        LocationPickerSection(viewModel: viewModel)
                         
                        
                        ExploreCityView(viewModel: viewModel)
                        
                        DailyChallengeView(
                            communityVM: communityVM,
                            showChallengePopup: $showChallengePopup,
                            selectedChallenge: $selectedChallenge,
                            challengeIndexToComplete: $challengeIndexToComplete
                        )
                    }
                    .padding()
                }
                .blur(radius: showChallengePopup ? 3 : 0)
                
                if showChallengePopup, let challenge = selectedChallenge, let index = challengeIndexToComplete {
                    ChallengePopupView(
                        challenge: challenge,
                        onDismiss: {
                            showChallengePopup = false
                            selectedChallenge = nil
                            challengeIndexToComplete = nil
                        },
                        onComplete: { photo, review, rating, recommended in
                            NotificationCenter.default.post(
                                name: NSNotification.Name("CompleteChallenge"),
                                object: nil,
                                userInfo: [
                                    "index": index,
                                    "photo": photo,
                                    "review": review,
                                    "rating": rating,
                                    "recommended": recommended
                                ]
                            )
                            showChallengePopup = false
                            selectedChallenge = nil
                            challengeIndexToComplete = nil
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .task {
                await viewModel.loadInitialData()
            }
            .onAppear {
                viewModel.checkAndRequestPermissionsIfNeeded()
            }
            .alert("Calendar Update", isPresented: $viewModel.showScheduleAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.scheduleAlertMessage)
            }
            .alert(isPresented: $viewModel.showCSVAlert) {
                Alert(
                    title: Text(viewModel.csvErrorMessage == nil ? "✅ CSV Generado" : "❌ Error"),
                    message: Text(viewModel.csvErrorMessage ?? viewModel.scheduleAlertMessage + "\n\n¿Quieres compartirlo?"),
                    primaryButton: viewModel.csvErrorMessage == nil ? .default(Text("Compartir")) {
                        viewModel.shareCSV()
                    } : .cancel(),
                    secondaryButton: .cancel(Text("OK"))
                )
            }
        }
    }
}

// MARK: - CSV Option Card Component
struct CSVOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let badge: String
    let badgeColor: Color
    let estimatedCost: String
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(icon)
                .font(.system(size: 32))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(badgeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badgeColor.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                
                Text(estimatedCost)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(14)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: backgroundColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}


// MARK: - Subviews (sin cambios)
struct HeaderGreetingView: View {
    var name: String
    
    var body: some View {
        VStack {
            Text("FWC26")
                .font(.title.weight(.heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 10)
            
            Spacer()
            
            HStack {
                NavigationLink(destination: ProfileView()) { }
                Spacer()
                
                Text("Hola, \(name)")
                    .padding(.leading, 7)
                    .font(Font.theme.headline)
                    .foregroundColor(Color.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 1) {
                    Image(systemName: "mappin")
                        .font(.system(size: 16))
                        .foregroundColor(.secondaryText)
                    Text("Ciudad de México")
                        .font(Font.theme.caption)
                        .foregroundColor(Color.secondaryText)
                }
            }
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "calendar")
                .padding(.top, -15)
                .padding(.leading, 6)
                .font(.system(size: 25))
                .foregroundColor(.white)
            
            VStack(alignment: .leading) {
                Text("Explora la ciudad")
                    .padding(.top, 23)
                    .font(Font.theme.headline)
                    .foregroundColor(Color.primaryText)
                
                Text("Te recomendamos los mejores momentos de acuerdo a tu calendario.")
                    .font(Font.theme.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 5)
                    .foregroundColor(.white)
            }
            .padding(.leading, 10)
        }
    }
}

struct ScoreView: View {
    var points: Int
    
    private var progress: Double {
        Double(points % 1000) / 1000.0
    }
    
    private var placesNeeded: Int {
        let remaining = 1000 - (points % 1000)
        return max(1, remaining / 500)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tu puntuación")
                    .fontWeight(.medium)
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 15))
                    Text("\(points) pts")
                }
            }
            .font(Font.theme.subheadline)
            .foregroundColor(Color.primaryText)
            
            ProgressView(value: progress)
                .tint(.white)
            
            Text("¡Visita dos lugares más para subir de nivel!")
                .font(Font.theme.caption)
                .foregroundColor(Color.secondaryText)
            
            Button(action: {
                print("Botón presionado")
            }) {
                HStack(spacing: 4) {
                    Text("Descubre cómo los demás están ganando puntos")
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 12))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#1738EA"))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

struct NoSuggestionsView: View {
    var body: some View {
        VStack {
            Text("No suggestions right now.")
                .font(Font.theme.body)
                .foregroundColor(Color.secondaryText)
            Text("Check back when you have more free time!")
                .font(Font.theme.caption)
                .foregroundColor(Color.secondaryText)
        }
    }
}

struct CalendarAccessPromptView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Get personalized suggestions!")
                .font(Font.theme.headline)
            Text("Enable calendar access in your iPhone's Settings to see local recommendations.")
                .font(Font.theme.body)
                .foregroundColor(Color.secondaryText)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(30)
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.leading, 15)
    }
}

struct DailyChallengeView: View {
    @State private var challenges: [Challenge] = MockData.challengesAvailable
    @State private var showPointsAnimation = false
    @State private var earnedPoints = 0
    @State private var totalPoints = 0
    
    @ObservedObject var communityVM: CommunityViewModel
    @EnvironmentObject var userData: UserDataManager
    
    @Binding var showChallengePopup: Bool
    @Binding var selectedChallenge: Challenge?
    @Binding var challengeIndexToComplete: Int?
    
    var completedChallenges: Int {
        challenges.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    VStack(spacing: 6) {
                        Text("Desafíos del día")
                            .font(Font.theme.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Completa los desafíos para acumular puntos y compite para que tu equipo quede en podio")
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                    
                    Text("\(completedChallenges)/\(challenges.count)")
                        .font(Font.theme.caption)
                }
                .foregroundColor(Color.primaryText)
                .padding(.bottom, 10)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(challenges.enumerated()), id: \.element.id) { index, challenge in
                            ChallengeCard(
                                challenge: challenge,
                                onComplete: {
                                    selectedChallenge = challenge
                                    challengeIndexToComplete = index
                                    showChallengePopup = true
                                }
                            )
                        }
                    }
                }
                .frame(height: 200)
                
                Image("component1")
                    .resizable()
                    .frame(width: 350, height: 60)
            }
            .padding()
            .padding(.top, 20)
            .background(Color.secondaryBackground.opacity(0.5))
            .cornerRadius(16)
            
            if showPointsAnimation {
                PointsAnimationView(points: earnedPoints)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(3)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CompleteChallenge"))) { notification in
            guard let userInfo = notification.userInfo,
                  let index = userInfo["index"] as? Int,
                  let photo = userInfo["photo"] as? UIImage,
                  let review = userInfo["review"] as? String,
                  let rating = userInfo["rating"] as? Int,
                  let recommended = userInfo["recommended"] as? Bool else { return }
            
            completeChallenge(at: index, photo: photo, review: review, rating: rating, recommended: recommended)
        }
    }
    
    private func completeChallenge(at index: Int, photo: UIImage, review: String, rating: Int, recommended: Bool) {
        guard !challenges[index].isCompleted else { return }
        
        var challenge = challenges[index]
        challenge.isCompleted = true
        challenge.completionDate = Date()
        challenge.photoEvidence = photo
        challenge.review = review
        challenge.rating = rating
        challenge.recommended = recommended
        
        challenges[index] = challenge
        
        var updatedUser = userData.user
        updatedUser.points += challenge.pointsAwarded
        updatedUser.completedChallenges.append(challenge)
        userData.user = updatedUser
        
        communityVM.updateLeaderboard(for: userData.user.teamPreference, adding: challenge.pointsAwarded)
        
        communityVM.addChallengePost(
            challengeTitle: challenge.title,
            photo: photo,
            review: review,
            rating: rating,
            recommended: recommended
        )
        
        earnedPoints = challenge.pointsAwarded
        totalPoints += earnedPoints
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showPointsAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showPointsAnimation = false
            }
        }
    }
}

#Preview {
    HomeView(communityVM: CommunityViewModel())
        .environmentObject(UserDataManager.shared)  // ✅ Usar .shared
}
