//
//  ClusteredMapView.swift
//  fifa2025
//
//  Created by Georgina on 16/10/25.
//  Updated: Clean callout + Beautiful sheet design
//

import SwiftUI
import MapKit

// MARK: - ClusteredMapView con Soporte para Selección
struct ClusteredMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let locations: [MapLocation]
    @Binding var selectedLocation: MapLocation?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: "CustomAnnotation")
        mapView.register(ClusteringAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        mapView.showsBuildings = true
            
        if #available(iOS 17.0, *) {
            let configuration = MKStandardMapConfiguration(elevationStyle: .realistic)
            mapView.preferredConfiguration = configuration
        }
            
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
            
        let camera = MKMapCamera(
            lookingAtCenter: region.center,
            fromDistance: 5000,
            pitch: 60,
            heading: 0
        )
        mapView.camera = camera
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if uiView.region.center.latitude != region.center.latitude ||
           uiView.region.span.latitudeDelta != region.span.latitudeDelta {
            let camera = MKMapCamera(
                        lookingAtCenter: region.center,
                        fromDistance: regionToDistance(region),
                        pitch: 60,
                        heading: uiView.camera.heading
                    )
                    uiView.setCamera(camera, animated: true)
        }
        
        context.coordinator.parent = self
        
        let oldAnnotations = uiView.annotations.compactMap { $0 as? LocationAnnotation }
        let oldLocationIds = Set(oldAnnotations.map { $0.locationID })
        let newLocationIds = Set(locations.map { $0.id })

        let annotationsToRemove = oldAnnotations.filter { !newLocationIds.contains($0.locationID) }
        if !annotationsToRemove.isEmpty {
            uiView.removeAnnotations(annotationsToRemove)
        }

        let annotationsToAdd = locations
            .filter { !oldLocationIds.contains($0.id) }
            .map { LocationAnnotation(location: $0) }
        
        if !annotationsToAdd.isEmpty {
            uiView.addAnnotations(annotationsToAdd)
        }
    }
    
    private func regionToDistance(_ region: MKCoordinateRegion) -> CLLocationDistance {
        let span = region.span
        let centerLatitude = region.center.latitude
        let metersPerDegree = 111000.0 * cos(centerLatitude * .pi / 180)
        return span.longitudeDelta * metersPerDegree
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ClusteredMapView

        init(_ parent: ClusteredMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
        
        // MARK: - Configurar Vista de Anotación
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let locationAnnotation = annotation as? LocationAnnotation else { return nil }
            
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "CustomAnnotation") as? CustomAnnotationView {
                annotationView.annotation = annotation
                annotationView.configure(with: locationAnnotation)
                return annotationView
            }
            
            let annotationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnotation")
            annotationView.configure(with: locationAnnotation)
            return annotationView
        }
        
        // MARK: - Manejar Selección de Anotación (Abrir Sheet)
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let locationAnnotation = view.annotation as? LocationAnnotation else { return }
            
            // Encontrar la ubicación completa y abrir sheet
            if let location = parent.locations.first(where: { $0.id == locationAnnotation.locationID }) {
                DispatchQueue.main.async {
                    self.parent.selectedLocation = location
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            // Opcional: limpiar selección si es necesario
        }
    }
}

// MARK: - Vista de Anotación Personalizada (SIMPLIFICADA - Sin popup complejo)
final class CustomAnnotationView: MKMarkerAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "location"
        collisionMode = .circle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with annotation: LocationAnnotation) {
        // Configurar marcador con colores modernos
        markerTintColor = colorForLocationType(annotation.locationType)
        glyphImage = UIImage(systemName: annotation.locationType.sfSymbol)
        glyphTintColor = .white
        
        // Aplicar sombra al marcador
        layer.shadowColor = markerTintColor?.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.3
        
        // Callout simple - solo muestra el título del marcador
        // Todo el detalle se maneja en el sheet
        canShowCallout = true
    }
    
    private func colorForLocationType(_ type: LocationType) -> UIColor {
        switch type {
        case .food: return UIColor(hex: "#FF8C42") // Naranja moderno
        case .shop: return UIColor(hex: "#A855F7") // Púrpura moderno
        case .cultural: return UIColor(hex: "#1738EA") // Azul primario
        case .stadium: return UIColor(hex: "#B1E902") // Verde acento
        case .entertainment: return UIColor(hex: "#EC4899") // Rosa moderno
        case .souvenirs: return UIColor(hex: "#FBBF24") // Amarillo moderno
        case .others: return UIColor(hex: "#6B7280") // Gris moderno
        }
    }
}

// MARK: - Vista de Cluster Moderna
final class ClusteringAnnotationView: MKMarkerAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        clusteringIdentifier = "location"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        
        if let cluster = annotation as? MKClusterAnnotation {
            let primaryColor = UIColor(hex: "#1738EA")
            
            markerTintColor = primaryColor
            glyphTintColor = .white
            glyphText = "\(cluster.memberAnnotations.count)"
            
            // Aplicar sombra moderna
            layer.shadowColor = primaryColor.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowRadius = 10
            layer.shadowOpacity = 0.4
            
            // Animación de aparición suave
            transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.transform = .identity
            }
            
            canShowCallout = true
        }
    }
}

// MARK: - LocationAnnotation
final class LocationAnnotation: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let locationType: LocationType
    let locationID: String
    var location: MapLocation?

    init(location: MapLocation) {
        self.title = location.name
        self.subtitle = location.description
        self.coordinate = location.coordinate
        self.locationType = location.type
        self.locationID = location.id
        self.location = location
        super.init()
    }
}

// MARK: - 🎨 LOCATION DETAIL SHEET (Matching ChallengePopupView Design)
struct LocationDetailSheet: View {
    let location: MapLocation
    @Environment(\.dismiss) var dismiss
    
    @State private var rating: Int = 0
    @State private var reviewText = ""
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradiente de fondo (igual que ChallengePopupView)
                LinearGradient(
                    colors: [Color(hex: "#1738EA"), Color(hex: "#18257E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 🎯 HEADER SECTION
                        VStack(spacing: 16) {
                            // Icono grande con efecto glow
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#B1E902").opacity(0.2))
                                    .frame(width: 90, height: 90)
                                    .blur(radius: 20)
                                
                                Circle()
                                    .fill(Color(hex: "#B1E902").opacity(0.3))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: location.type.sfSymbol)
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(Color(hex: "#B1E902"))
                            }
                            .shadow(color: Color(hex: "#B1E902").opacity(0.4), radius: 20)
                            
                            // Nombre del lugar
                            Text(location.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            // Badge de categoría
                            HStack(spacing: 8) {
                                Image(systemName: location.type.sfSymbol)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(location.type.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "#18257E"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#B1E902"))
                            .cornerRadius(20)
                            
                            // Descripción
                            let description = location.description
                            if  !description.isEmpty {
                                Text(description)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.top, 20)
                        
                        // 📞 CONTACT SECTION (Card)
                        VStack(spacing: 0) {
                            // Título de sección
                            HStack {
                                Text("Contacto")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            
                            VStack(spacing: 12) {
                                // Dirección
                                if let address = location.address, !address.isEmpty {
                                    ContactInfoRow(
                                        icon: "mappin.circle.fill",
                                        title: "Dirección",
                                        value: address,
                                        iconColor: Color(hex: "#FF6B6B")
                                    )
                                }
                                
                                // Teléfono
                                if let phone = location.phoneNumber, !phone.isEmpty {
                                    ContactInfoRow(
                                        icon: "phone.circle.fill",
                                        title: "Teléfono",
                                        value: phone,
                                        iconColor: Color(hex: "#4ECDC4")
                                    )
                                }
                                
                                // Sitio web (si existe)
                                if let website = location.website, !website.isEmpty {
                                    ContactInfoRow(
                                        icon: "globe.circle.fill",
                                        title: "Sitio Web",
                                        value: website,
                                        iconColor: Color(hex: "#A855F7")
                                    )
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // ⭐ RATING SECTION (Card)
                        VStack(spacing: 16) {
                            Text("¿Cómo calificarías tu experiencia?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            rating = star
                                        }
                                    }) {
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .font(.system(size: 36))
                                            .foregroundColor(star <= rating ? Color(hex: "#B1E902") : .white.opacity(0.3))
                                            .scaleEffect(star == rating ? 1.2 : 1.0)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                        
                        // ✍️ REVIEW SECTION (Card)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cuéntanos tu experiencia")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            ZStack(alignment: .topLeading) {
                                if reviewText.isEmpty {
                                    Text("Escribe aquí tu reseña...")
                                        .foregroundColor(.white.opacity(0.4))
                                        .padding(.top, 8)
                                        .padding(.leading, 12)
                                }
                                
                                TextEditor(text: $reviewText)
                                    .frame(height: 120)
                                    .padding(8)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "#B1E902").opacity(0.3), lineWidth: 1.5)
                            )
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                        
                        // 💾 SAVE BUTTON
                        Button(action: {
                            saveReview()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Guardar")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "#18257E"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isFormValid() ?
                                Color(hex: "#B1E902") :
                                Color.gray.opacity(0.5)
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: isFormValid() ? Color(hex: "#B1E902").opacity(0.5) : .clear,
                                radius: 10
                            )
                        }
                        .disabled(!isFormValid())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Detalles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .alert("¡Reseña guardada!", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Tu reseña ha sido guardada exitosamente.")
            }
        }
    }
    
    private func isFormValid() -> Bool {
        return rating > 0 && !reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveReview() {
        // TODO: Implementar lógica para guardar la reseña en tu backend
        // Ejemplo:
        // let review = LocationReview(locationId: location.id, rating: rating, text: reviewText)
        // reviewService.save(review)
        
        showingSaveConfirmation = true
    }
}

// MARK: - Contact Info Row Component
struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icono circular con color
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Extensiones Helper
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
// MARK: - LocationType Extension
extension LocationType {
    var displayName: String {
        switch self {
        case .food: return "Comida"
        case .shop: return "Tienda"
        case .cultural: return "Cultural"
        case .stadium: return "Estadio"
        case .entertainment: return "Entretenimiento"
        case .souvenirs: return "Souvenirs"
        case .others: return "Otros"
        }
    }
}

