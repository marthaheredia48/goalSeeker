//
//  CommunityView.swift
//  fifa2025
//
//  Created by Georgina on 07/10/25.
//

import SwiftUI
import Combine

struct CommunityView: View {
    @ObservedObject var vm: CommunityViewModel
    private let localUser = UserModel(id: UUID(), username: "me_local", displayName: "You", avatarName: "user_local", country: "Mexico")
    
    var body: some View {
        NavigationStack {
            ZStack {
             
                ScrollView {
                    VStack(spacing: 0) {
                        Text("Goal Seeker")
                            .font(.title.weight(.heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 26)
                        
                        Image("component1")
                            .resizable()
                    
                            .frame(width: 370, height: 60)
                    
                        
                     
                        LeaderboardPreviewView(entries: vm.leaderboard)
                            .padding(.horizontal)
                            .background(
                                NavigationLink(value: vm.leaderboard) {
                                    EmptyView()
                                }.opacity(0)
                            )
                        
                     
                        
                        Text("Jugadas del día")
                            .fontWeight(.medium)
                            .font(Font.theme.subheadline)
                            .foregroundColor(.white)
                          
                            .padding(.leading,-183)
                            .padding(.bottom, 8)
                            
                        
                        VStack(spacing: 12) {
                            ForEach(vm.posts) { post in
                                PostCardView(
                                    post: post,
                                    onLike: { vm.toggleLike(postId: post.id) },
                                    onAddComment: { text in vm.addComment(postId: post.id, commentText: text, from: localUser) }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color("BackgroudColor").ignoresSafeArea())
            .navigationDestination(for: [LeaderboardEntry].self) { entries in
                LeaderboardFullView(entries: entries)
            }
        }
    }
}
#Preview {
    CommunityView(vm: CommunityViewModel())
}



// MARK: - Leaderboard preview
struct LeaderboardPreviewView: View {
    let entries: [LeaderboardEntry]
    @State private var animateBars = false
    
    
    private var maxPoints: Int {
        entries.prefix(3).map { $0.points }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack(alignment: .bottom, spacing: 12) {
                
                ForEach(podiumOrder(), id: \.entry.id) { item in
                    VStack(spacing: 2) {
                   
                        Text(item.entry.flagEmoji)
                            .font(.system(size: 32))
                            .padding(.bottom, 8)
                        
                       
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: barColors(for: item.position),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: animateBars ? barHeight(for: item.entry.points) : 20)
                            .overlay(
                                VStack {
                                    Text("\(item.position + 1)")
                                        .padding(.top, 7)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(item.position == 2 ? Color(hex: "#B1E902") : .white)
                                    
                                    Spacer()
                                   
                                  
                                    Text(item.entry.country)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.bottom, 25)
                                }
                            )
                            .shadow(color: barColors(for: item.position)[0].opacity(0.5), radius: 8, y: 4)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 8)
            .padding(.bottom, 14)
      
            VStack(spacing: 4) {
                Text("Equipos liderando el podio")
                    .fontWeight(.medium)
                    .font(Font.theme.subheadline)
                    .foregroundColor(Color.primaryText)
                
                Text("¡Suma puntos para México completando los desafíos diarios!")
                    .font(Font.theme.caption)
                    .foregroundColor(Color.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            

            Button(action: {
                print("Botón presionado")
            }) {
                HStack(spacing: 4) {
                    Text("Visualiza el puntaje de los demás equipos")
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
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateBars = true
            }
        }
    }
    
    
    private func barHeight(for points: Int) -> CGFloat {
        let minHeight: CGFloat = 80
        let maxHeight: CGFloat = 180
        let ratio = CGFloat(points) / CGFloat(maxPoints)
        return minHeight + (maxHeight - minHeight) * ratio
    }
   
    private func barColors(for index: Int) -> [Color] {
        switch index {
        case 0:
            return [Color(hex: "#18257E"), Color(hex: "#4DD0E2")]
        case 1:
            return [Color(hex: "#18257E"), Color(hex: "#B189FC")]
        case 2:
            return [Color(hex: "#18257E"), Color(hex: "#2F4FFC")]
        default:
            return [Color.gray, Color.gray.opacity(0.7)]
        }
    }
    private func podiumOrder() -> [(entry: LeaderboardEntry, position: Int)] {
        let top3 = Array(entries.prefix(3))
        guard top3.count == 3 else {
            return top3.enumerated().map { (entry: $1, position: $0) }
        }
      
        return [
            (entry: top3[1], position: 1),
            (entry: top3[0], position: 0),
            (entry: top3[2], position: 2)
        ]
    }
}

// MARK: - Full leaderboard con barras
struct LeaderboardFullView: View {
    let entries: [LeaderboardEntry]
    @State private var animateBars = false
    
    private var maxPoints: Int {
        entries.map { $0.points }.max() ?? 1
    }
    
    var body: some View {
        ZStack {
            Color("BackgroudColor").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: 12) {
                   
                            Text("\(index + 1)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(positionColor(for: index))
                                .frame(width: 30)
                            
                   
                            Text(entry.flagEmoji)
                                .font(.system(size: 32))
                            
              
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.country)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                      
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                    
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 12)
                                        
                         
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "#1738EA"), Color(hex: "#B1E902")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(
                                                width: animateBars ? geo.size.width * CGFloat(entry.points) / CGFloat(maxPoints) : 0,
                                                height: 12
                                            )
                                    }
                                }
                                .frame(height: 12)
                            }
                            
                          
                            Text("\(entry.points)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#B1E902"))
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondaryBackground.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    index < 3 ? positionColor(for: index).opacity(0.5) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateBars = true
            }
        }
    }
    
    private func positionColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(hex: "#FFD700")
        case 1: return Color(hex: "#C0C0C0")
        case 2: return Color(hex: "#CD7F32")
        default: return Color.white
        }
    }
}




// MARK: - Post card
struct PostCardView: View {
    @State private var showCommentsSheet = false
    @State private var commentText = ""
    
    let post: PostModel
    let onLike: () -> Void
    let onAddComment: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
         
            HStack {
                Image(post.user.avatarName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3)))
                
                VStack(alignment: .leading) {
                    Text(post.user.displayName)
                        .bold()
                        .foregroundColor(.white)
                    Text("@\(post.user.username)   Apoya a \(post.user.country)")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                Spacer()
                
                VStack{
                    if post.challengePhoto != nil {
                        HStack(spacing: 2) {
                           
                            
                            Text("¡Completó un desafío!")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black)
                            
                            
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        
                        .background(Color(hex: "#B1E902"))
                        .cornerRadius(20)
                        .padding(.bottom, 4)
                    }

                   
                    
                }
               
            }
            
            if post.challengePhoto != nil {
                HStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(Color(hex: "#B1E902"))
                        .font(.system(size: 16))
                    
                    Text("Desafío completado: \(post.businessName)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                .background(Color(hex: "#4DD0E2"))
                .cornerRadius(20)
                
                .padding(.bottom, 4)
            }

        
            if let challengePhoto = post.challengePhoto {
               
                Image(uiImage: challengePhoto)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 240)
                    .clipped()
                    .cornerRadius(8)
                
                
                
            } else {
               
                Image(post.businessImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 240)
                    .clipped()
                    .cornerRadius(8)
            }
       
                        if let rating = post.rating, let recommended = post.recommended {
                            HStack(spacing: 16) {
                              
                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .foregroundColor(star <= rating ? Color(hex: "#B1E902") : .gray.opacity(0.4))
                                            .font(.system(size: 16))
                                    }
                                }
                                
                                Spacer()
                                
                                
                                VStack(spacing: 6) {
                                    Image(systemName: recommended ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                        .foregroundColor(recommended ? Color(hex: "#B1E902") : .red.opacity(0.8))
                                        .font(.system(size: 18))
                                    
                                    Text(recommended ? "Recomendado" : "No recomendado")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(recommended ? Color(hex: "#B1E902") : .red.opacity(0.8))
                                }
                            }
                           
                           
                            
                        }
                        
            
            Text(post.businessName)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
            
            Text(post.text)
                .font(.body)
                .foregroundColor(.white)
            
            HStack {
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(.white)
                        Text("\(post.likes)")
                            .foregroundColor(.white)
                    }
                }
                
                Button(action: { showCommentsSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.white)
                        Text("\(post.comments.count)")
                            .foregroundColor(.white)
                    }
                }
                Spacer()
            }
            .buttonStyle(.plain)
            .font(.subheadline)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondaryBackground.opacity(0.5)).shadow(radius: 1))
        .sheet(isPresented: $showCommentsSheet) {
            CommentsSheet(post: post, onAdd: { text in onAddComment(text) })
        }
    }
}

// MARK: - Comments sheet
struct CommentsSheet: View {
    @Environment(\.dismiss) var dismiss
    let post: PostModel
    @State private var newComment: String = ""
    let onAdd: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
  
                Color("BackgroudColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
            
                    List {
                        ForEach(post.comments) { c in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(c.user.avatarName)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                    Text(c.user.displayName)
                                        .bold()
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(c.date, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Text(c.text)
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.secondaryBackground.opacity(0.3))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    
              
                    HStack(spacing: 12) {
                        ZStack(alignment: .leading) {
                          
                            if newComment.isEmpty {
                                Text("Add a comment...")
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.leading, 12)
                            }
                            
                            TextField("", text: $newComment)
                                .padding(12)
                                .foregroundColor(.white)
                        }
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        
                        Button(action: {
                            guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            onAdd(newComment)
                            newComment = ""
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(hex: "#1738EA"))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .background(Color.secondaryBackground.opacity(0.5))
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.secondaryBackground.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
