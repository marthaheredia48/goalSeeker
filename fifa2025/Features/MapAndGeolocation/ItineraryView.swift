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
                    .foregroundColor(Color(hex: "#18257E"))
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
