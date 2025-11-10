//
//  ExploreCityView.swift
//  fifa2025
//
//  Created by Georgina on 12/10/25.
//


import SwiftUI

struct ExploreCityView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView { // Scroll vertical si quieres que se pueda scrollear
            VStack(spacing: 35) {
                if viewModel.suggestions.isEmpty {
                    VStack {
                        Text("¡No hay sugerencias por ahora!")
                            .font(Font.theme.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)
                        Text("¡Vuelve más tarde cuando tengas un poco de tiempo libre!")
                            .font(Font.theme.caption)
                            .foregroundColor(Color.secondaryText.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.suggestions, id: \.id) { suggestion in
                            SuggestionCard(suggestion: suggestion, viewModel: viewModel)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(16)
                                .shadow(radius: 4)
                        }
                    }
                }
            }
        }
        .background(Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
        .padding()
    }
}
