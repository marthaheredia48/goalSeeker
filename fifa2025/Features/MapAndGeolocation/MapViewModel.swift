import Foundation
import MapKit
import SwiftUI
import Combine

@MainActor
final class MapViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var filteredLocations: [MapLocation] = []
    @Published var mapRegion: MKCoordinateRegion
    @Published var errorMessage: String?
    @Published var showAlert: Bool = false
    @Published var isLoading: Bool = false
    @Published var selectedFilters: Set<LocationType> = Set(LocationType.allCases)
    
    // MARK: - Private Properties
    private let denueService = DENUEService()
    private var cancellables = Set<AnyCancellable>()
    
  
    private let locationService = SharedLocationService.shared
    
    private var locationCache = CacheManager<[MapLocation]>()
    private var fetchedGridKeys = Set<String>()
    private let gridCellSizeInMeters: CLLocationDistance = 2500
    
    private actor LocationStore {
        var locations: [MapLocation] = []

        func add(newLocations: [MapLocation]) {
            let existingIDs = Set(locations.map { $0.denueID })
            let uniqueNewLocations = newLocations.filter { !existingIDs.contains($0.denueID) }
            locations.append(contentsOf: uniqueNewLocations)
        }
        
        func getAll() -> [MapLocation] {
            return locations
        }
        
        func clear() {
            locations = []
        }
    }
    
    private let locationStore = LocationStore()

    init() {
        // ✅ Inicializar con la ubicación del singleton
        let currentLocation = SharedLocationService.shared.location
        self.mapRegion = MKCoordinateRegion(
            center: currentLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        setupBindings()
    }
    
    private func setupBindings() {
        $mapRegion
            .debounce(for: .milliseconds(750), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.updateVisibleGridAndFetchData()
                }
            }
            .store(in: &cancellables)
        
        $selectedFilters
            .sink { [weak self] _ in
                Task {
                    await self?.applyFilters()
                }
            }
            .store(in: &cancellables)
        
        // ⭐ CRÍTICO: Escuchar cambios de ubicación del singleton
        locationService.$location
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] newLocation in
                guard let self = self else { return }
                print("🗺️ MapViewModel detectó cambio de ubicación: (\(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude))")
                
                Task {
                    // Centrar el mapa en la nueva ubicación
                    await MainActor.run {
                        withAnimation {
                            self.mapRegion = MKCoordinateRegion(
                                center: newLocation.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            )
                        }
                    }
                    
                    // Limpiar datos anteriores y recargar
                    await self.locationStore.clear()
                    self.fetchedGridKeys.removeAll()
                    await self.updateVisibleGridAndFetchData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading and Orchestration
    
    func loadInitialData() async {
        // Cargar datos mock inicialmente
        self.filteredLocations = MockData.sampleLocations
        await updateVisibleGridAndFetchData()
    }
    
    private func updateVisibleGridAndFetchData() async {
        let centerKey = gridKey(for: mapRegion.center)
            
        guard !fetchedGridKeys.contains(centerKey) else { return }
        
        isLoading = true
        fetchedGridKeys.insert(centerKey)
            
        await withTaskGroup(of: Void.self) { group in
            for category in Array(selectedFilters) {
                group.addTask {
                    await self.loadBusinesses(
                        for: category,
                        gridKey: centerKey,
                        near: self.mapRegion.center,
                        radius: Int(self.gridCellSizeInMeters)
                    )
                }
            }
        }
            
        isLoading = false
    }

    private func loadBusinesses(for category: LocationType, gridKey: String, near coordinate: CLLocationCoordinate2D, radius: Int) async {
        let cacheKey = "\(gridKey)-\(category.rawValue)"

        if let cachedLocations = locationCache.getValue(forKey: cacheKey) {
            await addLocationsToMap(cachedLocations)
            return
        }
        
        do {
            let businesses = try await denueService.fetchBusinesses(
                for: category,
                gridKey: gridKey,
                near: coordinate,
                radiusInMeters: radius
            )
            locationCache.setValue(businesses, forKey: cacheKey)
            await addLocationsToMap(businesses)
        } catch {
            await MainActor.run {
                self.errorMessage = "Could not load some local businesses. Please check your connection."
                self.showAlert = true
            }
            print("Error fetching category \(category): \(error)")
        }
    }
    
    // MARK: - Filtering and State Management
    private func addLocationsToMap(_ newLocations: [MapLocation]) async {
        await locationStore.add(newLocations: newLocations)
        let allLocations = await locationStore.getAll()
        
        await MainActor.run {
            self.filteredLocations = allLocations.filter { location in
                selectedFilters.contains(location.type)
            }
        }
    }
    
    private func applyFilters() async {
        let allLocations = await locationStore.getAll()
        
        await MainActor.run {
            self.filteredLocations = allLocations.filter { location in
                selectedFilters.contains(location.type)
            }
        }
    }
    
    func toggleFilter(for type: LocationType) {
        if selectedFilters.contains(type) {
            selectedFilters.remove(type)
        } else {
            selectedFilters.insert(type)
            Task {
                await updateVisibleGridAndFetchData()
            }
        }
    }
    
    private func gridKey(for coordinate: CLLocationCoordinate2D) -> String {
        let latIndex = Int(coordinate.latitude * 100)
        let lonIndex = Int(coordinate.longitude * 100)
        return "\(latIndex)-\(lonIndex)"
    }
}
