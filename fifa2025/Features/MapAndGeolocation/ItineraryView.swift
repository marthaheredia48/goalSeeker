//
//  ItineraryView.swift
//  fifa2025
//
//  Created by Martha Heredia Andrade on 28/10/25.
//

import SwiftUI
import CoreLocation
import Combine
import MapKit

// MARK: - Vista Principal del Mapa (DIRECTA)
struct ItineraryMapViewDirect: View {
    @EnvironmentObject var userDataManager: UserDataManager
    @StateObject private var viewModel = ItineraryMapViewModel()
    @State private var selectedLocation: MapLocation? = nil
    @State private var rating: Int = 0
    @State private var reviewText: String = ""

    
    // ✅ USAR SINGLETON COMPARTIDO
    private let locationService = SharedLocationService.shared
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                VStack {
                    ProgressView("Generando tu itinerario...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                }
            } else if let itinerary = viewModel.currentItinerary {
                // MAPA CON PUNTOS
                ClusteredMapView(
                    region: $viewModel.mapRegion,
                    locations: itinerary.places.map { $0.place },
                    selectedLocation: $selectedLocation
                )
                .ignoresSafeArea()
                
                // Overlay con info resumida + ubicación actual
                VStack {
                    compactSummaryCard(itinerary)
                        .padding()
                    
                    Spacer()
                }
            } else {
                emptyState
            }
        }
        .sheet(item: $selectedLocation) { location in
            LocationDetailSheet(location: location)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await viewModel.generateItinerary(
                for: userDataManager.user,
                from: locationService.location
            )
        }
        // ⭐ CRÍTICO: Escuchar cambios del singleton
        .onReceive(locationService.$location) { newLocation in
            print("🗺️ Mapa detectó cambio: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
            Task {
                await viewModel.generateItinerary(
                    for: userDataManager.user,
                    from: newLocation
                )
            }
        }
    }
    
    // MARK: - Compact Summary Card
    private func compactSummaryCard(_ itinerary: SmartItinerarySuggestion) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tu Itinerario")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 12) {
                    Label("\(itinerary.places.count)", systemImage: "pin.fill")
                        .font(.caption)
                    Label(formatDuration(itinerary.totalDuration), systemImage: "clock.fill")
                        .font(.caption)
                    Label(String(format: "%.1f km", itinerary.totalDistance), systemImage: "map.fill")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                viewModel.centerMapOnItinerary()
            } label: {
                Image(systemName: "scope")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Generando tu itinerario")
                .font(.title2)
                .fontWeight(.bold)
            
            Button("Reintentar") {
                Task {
                    await viewModel.generateItinerary(
                        for: userDataManager.user,
                        from: locationService.location
                    )
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - ViewModel para el Mapa
@MainActor
final class ItineraryMapViewModel: ObservableObject {
    @Published var currentItinerary: SmartItinerarySuggestion?
    @Published var mapRegion: MKCoordinateRegion
    @Published var isLoading = false
    @Published var errorMessage: String?
    @State private var rating: Int = 0
    @State private var reviewText: String = ""

    
    init() {
        self.mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }
    
    func generateItinerary(for user: User, from location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        
        print("🗺️ Generando itinerario desde: (\(location.coordinate.latitude), \(location.coordinate.longitude))")
        
        let allLocations = SuggestionEngine.loadAllLocations()
        
        let suggestions = SuggestionEngine.generateSmartSuggestions(
            for: [],
            from: location,
            for: user,
            allLocations: allLocations
        )
        
        if let firstSuggestion = suggestions.first {
            currentItinerary = firstSuggestion
            let coordinates = firstSuggestion.places.map { $0.place.coordinate }
            mapRegion = calculateRegion(for: coordinates)
            
            print("✅ Itinerario generado con \(firstSuggestion.places.count) lugares")
        } else {
            errorMessage = "No se pudieron generar sugerencias"
            print("❌ No se generaron sugerencias")
        }
        
        isLoading = false
    }
    
    func centerMapOnItinerary() {
        guard let itinerary = currentItinerary else { return }
        let coordinates = itinerary.places.map { $0.place.coordinate }
        
        withAnimation {
            mapRegion = calculateRegion(for: coordinates)
        }
    }
    
    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        if coordinates.count == 1 {
            return MKCoordinateRegion(
                center: coordinates[0],
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        let totalLat = coordinates.reduce(0) { $0 + $1.latitude }
        let totalLon = coordinates.reduce(0) { $0 + $1.longitude }
        let center = CLLocationCoordinate2D(
            latitude: totalLat / Double(coordinates.count),
            longitude: totalLon / Double(coordinates.count)
        )
        
        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }
        let maxLat = lats.max() ?? 0
        let minLat = lats.min() ?? 0
        let maxLon = lons.max() ?? 0
        let minLon = lons.min() ?? 0
        
        let latDelta = (maxLat - minLat) * 1.5
        let lonDelta = (maxLon - minLon) * 1.5
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta, 0.02),
            longitudeDelta: max(lonDelta, 0.02)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Sheet de Detalles del Lugar
struct LocationDetailSheet: View {
    let location: MapLocation
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
            
                    contactSection
                    actionButtonsSection
                    
                    if location.promotesWomenInSports {
                        womenInSportsBadge
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Detalles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .center, spacing: 26) {

            HStack {
                Spacer() // Esto centra el contenido del HStack

                Image(systemName: location.type.sfSymbol)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(colorForLocationType(location.type))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.leading, 15)

                VStack(alignment: .center) {
                    
                    Text(location.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                    Text(location.type.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
         
            }

         
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
    }
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
        
            VStack(alignment: .center, spacing: 8) {
                Text("¿Cómo calificarías tu experiencia?")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 13) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.title2)
                            .onTapGesture {
                                rating = index
                            }
                    }
                }
            }
            
           
            VStack(alignment: .leading, spacing: 8) {
                Text("Cuéntanos tu experiencia")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ZStack(alignment: .topLeading) {
                    if reviewText.isEmpty {
                        Text("Escribe aquí tu reseña detallada")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 8)
                    }
                    
                    TextEditor(text: $reviewText)
                        .frame(height: 120)
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                Button {
                        print(" Guardado: \(rating) estrellas, review: \(reviewText)")
                     
                    } label: {
                        Text("Guardar")
                            .frame(maxWidth: 350)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.headline)
                    }
                    .padding(.top, 4)
            }

      
            if hasContactInfo {
                Text("Contacto")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let address = location.address, !address.isEmpty {
                    InfoRowView(
                        icon: "mappin.and.ellipse",
                        title: "Dirección",
                        content: address,
                        color: .red,
                        isExpandable: true
                    )
                }
                
                if let phone = location.phoneNumber, !phone.isEmpty {
                    Button {
                        if let url = URL(string: "tel:\(phone)") {
                            openURL(url)
                        }
                    } label: {
                        InfoRowView(
                            icon: "phone.fill",
                            title: "Teléfono",
                            content: phone,
                            color: .green,
                            isButton: true
                        )
                    }
                }
                
                if let website = location.website, !website.isEmpty {
                    Button {
                        let urlString = website.hasPrefix("http") ? website : "https://\(website)"
                        if let url = URL(string: urlString) {
                            openURL(url)
                        }
                    } label: {
                        InfoRowView(
                            icon: "safari.fill",
                            title: "Sitio Web",
                            content: website,
                            color: .purple,
                            isButton: true
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
    }

    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button {
                openInMaps()
            } label: {
                Label("Cómo llegar", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
           
        }
    }
    
    private var womenInSportsBadge: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text("Este lugar promueve a las mujeres en el deporte")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(12)
    }
    
    private var hasContactInfo: Bool {
        (location.address != nil && !location.address!.isEmpty) ||
        (location.phoneNumber != nil && !location.phoneNumber!.isEmpty) ||
        (location.website != nil && !location.website!.isEmpty)
    }
    
    private func colorForLocationType(_ type: LocationType) -> Color {
        switch type {
        case .food: return .orange
        case .shop: return .purple
        case .cultural: return .blue
        case .stadium: return .green
        case .entertainment: return .pink
        case .souvenirs: return .yellow
        case .others: return .gray
        }
    }
    
    private func openInMaps() {
        let coordinate = location.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
    
    private func shareLocation() {
        let text = """
        📍 \(location.name)
        \(location.description)
        
        Coordenadas: \(location.latitude), \(location.longitude)
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Info Row Component
struct InfoRowView: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    var isExpandable: Bool = false
    var isButton: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(isButton ? color : .primary)
                    .lineLimit(isExpandable ? nil : 2)
            }
            
            Spacer()
            
            if isButton {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}
