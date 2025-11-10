import SwiftUI

struct SmartItinerarySuggestionView: View {
    let suggestion: SmartItinerarySuggestion

    var body: some View {
        ZStack {
            Image("cdmx")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Itinerario: \(suggestion.places.count) lugares")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(suggestion.places.enumerated()), id: \.offset) { index, stop in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                Text(stop.place.name)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(timeString(from: stop.arrivalTime))
                                    .monospacedDigit()
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Label(durationString(suggestion.totalDuration), systemImage: "clock")
                        Label(String(format: "%.1f km", suggestion.totalDistance), systemImage: "figure.walk")
                    }
                    .foregroundStyle(.white)
                    
                    Button {
                        CalendarManager.shared.addSmartItinerary(suggestion) { _ in }
                    } label: {
                        Text("Guardar en Calendario")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
    
    private func durationString(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
