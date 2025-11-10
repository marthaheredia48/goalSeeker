//
//  AlbumView.swift
//  fifa2025
//
//  Created by Georgina on 02/10/25.
//


import SwiftUI
import Combine

// MARK: - ViewModel del Álbum
class AlbumViewModel: ObservableObject {
    @Published var recentCards: [WorldCupCard] = []
    @Published var allCards: [WorldCupCard] = []
    @Published var selectedCard: WorldCupCard?
    
    init() {
        loadSampleCards()
    }
    
    private func loadSampleCards() {
            recentCards = [
       
                WorldCupCard(id: UUID(), title: "Ciudad de México", subtitle: "Host City", hostCountry: "🇲🇽 México", imageName: "azteca", cardType: .stadium, rarity: .epic, isOwned: true, duplicateCount: 2),
        WorldCupCard(id: UUID(), title: "México", subtitle: "Host Country", hostCountry: "🇲🇽 México", imageName: "Country", cardType: .stadium, rarity: .legendary, isOwned: true, duplicateCount: 2),
                WorldCupCard(id: UUID(), title: "Vancouver", subtitle: "Host City", hostCountry: "🇨🇦Canada", imageName: "Culture1", cardType: .stadium, rarity: .epic, isOwned: true, duplicateCount: 1),
                WorldCupCard(id: UUID(), title: "United States", subtitle: "Host City", hostCountry: "🇺🇸 USA", imageName: "Culture2", cardType: .stadium, rarity: .epic, isOwned: true, duplicateCount: 0),
                WorldCupCard(id: UUID(), title: "USA", subtitle: "New York", hostCountry: "🇺🇸 USA", imageName: "Country1", cardType: .stadium, rarity: .legendary, isOwned: true, duplicateCount: 3),
                WorldCupCard(id: UUID(), title: "Canada", subtitle: "Maple", hostCountry: "🇨🇦Canada", imageName: "Country2", cardType: .stadium, rarity: .epic, isOwned: true, duplicateCount: 1),
                WorldCupCard(id: UUID(), title: "Stadium", subtitle: "Football", hostCountry: "🇨🇦 Canadá,🇲🇽 México,🇺🇸 USA", imageName: "Soccer", cardType: .stadium, rarity: .rare, isOwned: true, duplicateCount: 0),
                WorldCupCard(id: UUID(), title: "Soccer", subtitle: "Football", hostCountry: "🇨🇦 Canadá,🇲🇽 México,🇺🇸 USA", imageName: "Soccer1", cardType: .country, rarity: .rare, isOwned: true, duplicateCount: 5),
                WorldCupCard(id: UUID(), title: "Sport", subtitle: "Football", hostCountry: "🇨🇦 Canadá,🇲🇽 México,🇺🇸 USA", imageName: "Soccer2", cardType: .country, rarity: .rare, isOwned: true, duplicateCount: 5),
                WorldCupCard(id: UUID(), title: "Women’s World Cup", subtitle: "México 1971", hostCountry: "🇲🇽 México", imageName: "Women", cardType: .country, rarity: .legendary, isOwned: true, duplicateCount: 2),
                WorldCupCard(id: UUID(), title: "Canada’s Soccer", subtitle: "Hall of Fame", hostCountry: "🇨🇦 Canadá", imageName: "Women1", cardType: .country, rarity: .legendary, isOwned: true, duplicateCount: 2),
                WorldCupCard(id: UUID(), title: "Womens’ Soccer", subtitle: "USA", hostCountry: "🇺🇸 USA", imageName: "Women2", cardType: .country, rarity: .legendary, isOwned: true, duplicateCount: 2),
            ]
            
            allCards = recentCards
        }
    }

// MARK: - Vista Principal del Álbum
struct AlbumView: View {
    @StateObject private var viewModel = AlbumViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Goal Seeker")
                            .font(.title.weight(.heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                        
                        AlbumStatsView()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cartas recientes")
                                .fontWeight(.medium)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                      
                            AlbumCarouselView(viewModel: viewModel)
                        }
                        
                        AlbumCollectionGridView()
                    }
                    .padding(.vertical)
                }
            }
            .background(Color("BackgroudColor").ignoresSafeArea())
    
            .fullScreenCover(item: $viewModel.selectedCard) { card in
                FullImageView(card: card)
            }
        }
    }
}


// MARK: - Carrusel de Cartas
struct AlbumCarouselView: View {
    @ObservedObject var viewModel: AlbumViewModel
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDraggingHorizontally: Bool? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let cardWidth = geometry.size.width * 0.75
                let peekAmount: CGFloat = 40
                
                ZStack {
                    ForEach(Array(viewModel.recentCards.enumerated()), id: \.element.id) { index, card in
                        let distance = CGFloat(index - currentIndex)
                        let offset = distance * (cardWidth - peekAmount) + dragOffset
                        let scale = getScale(for: index)
                        let opacity = getOpacity(for: index)
                        
                        WorldCupCardView(card: card, viewModel: viewModel)
                            .frame(width: cardWidth)
                            .scaleEffect(scale)
                            .opacity(opacity)
                            .offset(x: offset)
                            .zIndex(index == currentIndex ? 10 : Double(5 - abs(index - currentIndex)))
                            .onTapGesture {
                                if index == currentIndex {
                                    viewModel.selectedCard = card
                                }
                            }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                  
                            if isDraggingHorizontally == nil {
                                let horizontalAmount = abs(value.translation.width)
                                let verticalAmount = abs(value.translation.height)
                                
                               
                                isDraggingHorizontally = horizontalAmount > verticalAmount
                            }
                            
                           
                            if isDraggingHorizontally == true {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                      
                            if isDraggingHorizontally == true {
                                let threshold: CGFloat = 50
                                
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if value.translation.width < -threshold && currentIndex < viewModel.recentCards.count - 1 {
                                        currentIndex += 1
                                    } else if value.translation.width > threshold && currentIndex > 0 {
                                        currentIndex -= 1
                                    }
                                    dragOffset = 0
                                }
                            }
                            
                         
                            isDraggingHorizontally = nil
                            dragOffset = 0
                        }
                )
            }
            .frame(height: 440)
            

            if let currentCard = viewModel.recentCards[safe: currentIndex] {
                ShareLink(
                    item: currentCard,
                    preview: SharePreview(
                        currentCard.title,
                        image: Image(currentCard.imageName)
                    )
                ) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.forward.app.fill")
                            .font(.system(size: 17))
                        Text("Compartir Carta")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#B1E902"), Color(hex: "#90C700")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "#B1E902").opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func getScale(for index: Int) -> CGFloat {
        let distance = abs(currentIndex - index)
        if distance == 0 { return 1.0 }
        if distance == 1 { return 0.9 }
        return 0.8
    }
    
    private func getOpacity(for index: Int) -> Double {
        let distance = abs(currentIndex - index)
        if distance == 0 { return 1.0 }
        if distance == 1 { return 0.7 }
        return 0.3
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct ReceivedCardView: View {
    let card: WorldCupCard
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color("BackgroudColor").ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("¡Has recibido una carta!")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.white)

                WorldCupCardView(card: card, viewModel: AlbumViewModel())
                    .scaleEffect(0.9)

                Button(action: {
                    print("Agregando \(card.title) a la colección.")
                    dismiss()
                }) {
                    Text("Agregar al álbum")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#B1E902"))
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Vista de Carta Individual
struct WorldCupCardView: View {
    let card: WorldCupCard
    @ObservedObject var viewModel: AlbumViewModel
    
    var body: some View {
        VStack(spacing: 0) {
        
            ZStack {
             
                Image(card.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 380)
                    .clipped()
                
              
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.5),
                        Color.clear,
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(card.rarity.color, lineWidth: 4)
                
    
                VStack(spacing: 0) {
       
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: card.cardType.icon)
                                .font(.system(size: 14))
                            Text(card.cardType.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                        
                        Spacer()
                        
                        
                        Text(card.rarity.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(card.rarity.color)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Spacer()
                    
          
                    VStack(spacing: 8) {
                       
                        
        
                        Text(card.title)
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                        
            
                        Text(card.subtitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
           
                        Text(card.hostCountry)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                        
             
                        if card.duplicateCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 13))
                                Text("x\(card.duplicateCount + 1)")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(card.rarity.color)
                            .cornerRadius(12)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(height: 420)
            .cornerRadius(20)
        }
        .cornerRadius(20)
        .shadow(color: card.rarity.color.opacity(0.5), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Estadísticas del Álbum
struct AlbumStatsView: View {
    var body: some View {
        HStack(spacing: 16) {
            StatCardView(title: "Estadios", value: "6/16", icon: "building.2.fill", color: Color(hex: "#2F4FFC"))
            StatCardView(title: "Países", value: "3/48", icon: "flag.fill", color: Color(hex: "#B1E902"))
            StatCardView(title: "Duplicados", value: "0", icon: "doc.on.doc.fill", color: Color.orange)
        }
        .padding(.horizontal, 24)
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Grid de Colección
struct AlbumCollectionGridView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tu colección")
                    .fontWeight(.medium)
                Spacer()
                
                HStack (spacing: 2){
                    
                    Text("12/300")
                    
                }
                
                
                
            }
            .font(Font.theme.subheadline)
            .foregroundColor(Color.primaryText)

            ProgressView(value: 0.35)
                .tint(.white)
            
                        
        }
        .padding()
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(26)
    }
}

struct MiniCardView: View {
    let card: WorldCupCard
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.rarity.gradient)
                
                VStack(spacing: 4) {
                    Image(systemName: card.cardType.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Image(card.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 12)
                
                if card.duplicateCount > 0 {
                    Text("x\(card.duplicateCount + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        .padding(6)
                }
            }
            .frame(height: 110)
            
            Text(card.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Vista de Imagen Completa (Pop-up)
struct FullImageView: View {
    let card: WorldCupCard
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
             
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                
                Spacer()
                
         
                Image(card.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(card.rarity.color, lineWidth: 4)
                    )
                    .shadow(color: card.rarity.color.opacity(0.6), radius: 20, x: 0, y: 10)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    scale = 1.0
                                }
                            }
                    )
                    .padding()
                
    
                VStack(spacing: 8) {
                    Text(card.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(card.subtitle)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(card.rarity.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(card.rarity.color)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Share Sheet (AirDrop, etc.)
struct ShareSheet: UIViewControllerRepresentable {
    let card: WorldCupCard
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let text = "¡Mira esta carta de mi álbum! 🏆\n\n\(card.title) - \(card.subtitle)\nRareza: \(card.rarity.rawValue)\n\n¿Quieres intercambiar?"
        
        let items: [Any] = [text]
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
       
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .saveToCameraRoll
        ]
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


