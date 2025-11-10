//
//  SuggestionCardView.swift
//  fifa2025
//
//  Created by Georgina on 09/10/25.
//

import SwiftUI

struct SuggestionCard: View {
    let suggestion: SmartItinerarySuggestion
    @ObservedObject var viewModel: HomeViewModel
    
    private var firstPlace: MapLocation? {
        suggestion.places.first?.place
    }
    
    private var startTime: Date? {
        suggestion.places.first?.arrivalTime
    }
    
    private var endTime: Date? {
        suggestion.places.last?.departureTime
    }
    
    private var formattedDuration: String {
        let hours = Int(suggestion.totalDuration / 3600)
        let minutes = Int((suggestion.totalDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con imagen del primer lugar
            ZStack(alignment: .top) {
                if let firstPlace = firstPlace {
                    Image("cdmx")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                } else {
                    Color.gray.opacity(0.3)
                        .frame(height: 180)
                }
                
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear, Color.black.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Time badge
                if let startTime = startTime, let endTime = endTime {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 13))
                        Text(startTime, style: .time)
                            .font(.system(size: 13, weight: .medium))
                        Text("—")
                        Text(endTime, style: .time)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(16)
                    .padding(.top, 12)
                }
                
                // Title en la parte inferior del header
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    
                    Text("Itinerario Sugerido")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(.bottom, 5)
                    Text("Te recomendamos los mejores lugares!")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(.bottom, 5)
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 12))
                            Text("\(suggestion.places.count) lugares")
                                .font(.system(size: 13, weight: .medium))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                            Text(formattedDuration)
                                .font(.system(size: 13, weight: .medium))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.swap")
                                .font(.system(size: 12))
                            Text(String(format: "%.1f km", suggestion.totalDistance))
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .foregroundColor(.white.opacity(0.95))
                }
                .padding(16)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 180)
            
            // Lista de lugares
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(Array(suggestion.places.enumerated()), id: \.offset) { index, stop in
                        ItineraryStopRow(
                            stop: stop,
                            index: index + 1,
                            isLast: index == suggestion.places.count - 1
                        )
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .frame(height: 185)
            .background(Color.white.opacity(0.05))
            
            // Action buttons
            HStack(spacing: 10) {
               
                
                Button(action: {
                    viewModel.scheduleSuggestion(suggestion)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 15))
                        Text("Agendar")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#2F4FFC"))
                    .cornerRadius(14)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.15))
        }
        .background(Color.white.opacity(0.08))
        .cornerRadius(24)
    }
}

// MARK: - Itinerary Stop Row
struct ItineraryStopRow: View {
    let stop: ItineraryStop
    let index: Int
    let isLast: Bool
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: stop.arrivalTime)
    }
    
    private var durationMinutes: Int {
        Int(stop.suggestedDuration / 60)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(stop.mealType != nil ? Color.orange : Color(hex: "#2F4FFC"))
                        .frame(width: 24, height: 24)
                    
                    if stop.mealType != nil {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(index)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }
            
            // Place info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stop.place.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let mealType = stop.mealType {
                        Text(mealType.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.8))
                            .cornerRadius(8)
                    }
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(formattedTime)
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 11))
                        Text("\(durationMinutes) min")
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    Text(stop.place.type.type)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)
                }
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Subviews (mantener compatibilidad)
struct InfoPill: View {
    let text: LocalizedStringKey
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.2))
            .cornerRadius(20)
    }
}

struct ActionButton: View {
    let title: LocalizedStringKey
    let icon: String
    var isPrimary: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.footnote.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding()
            .background(isPrimary ? Color("MainButtonColor") : .white.opacity(0.2))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}
