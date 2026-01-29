//
//  OnboardingView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/29.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var petName: String = ""
    @State private var ownerNickname: String = ""
    @State private var isAnimating = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Welcome Header
                VStack(spacing: 15) {
                    Image("dog_default") // Fallback image asset name, ensure it exists or use system image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text("欢迎来到 PetWalk")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.appBrown)
                    
                    Text("让我们先来认识一下彼此吧")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Input Fields
                VStack(spacing: 20) {
                    inputField(
                        title: "你的爱宠叫什么名字？",
                        placeholder: "例如：旺财、Cookie...",
                        text: $petName,
                        icon: "pawprint.fill"
                    )
                    
                    inputField(
                        title: "它平时怎么称呼你？",
                        placeholder: "例如：爸爸、妈妈、主人...",
                        text: $ownerNickname,
                        icon: "person.fill"
                    )
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Action Button
                Button {
                    completeOnboarding()
                } label: {
                    HStack {
                        Text("开启旅程")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValid ? Color.appGreenMain : Color.gray.opacity(0.3))
                    .cornerRadius(15)
                    .shadow(color: isValid ? .appGreenMain.opacity(0.4) : .clear, radius: 10, y: 5)
                }
                .disabled(!isValid)
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var isValid: Bool {
        !petName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !ownerNickname.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func completeOnboarding() {
        var userData = dataManager.userData
        userData.petName = petName.trimmingCharacters(in: .whitespaces)
        userData.ownerNickname = ownerNickname.trimmingCharacters(in: .whitespaces)
        userData.hasCompletedOnboarding = true
        dataManager.updateUserData(userData)
        
        withAnimation {
            onComplete()
        }
    }
    
    private func inputField(title: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.appBrown)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                TextField(placeholder, text: text)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
