//
//  PetProfileSetupView.swift
//  PetWalk
//
//  Created by User on 2026/01/30.
//

import SwiftUI

struct PetProfileSetupView: View {
    
    // MARK: - State
    @State private var currentStep = 0
    @State private var name: String = ""
    @State private var ownerName: String = ""
    @State private var profile: PetProfile = PetProfile()
    
    // Animation states
    @State private var isAnimating = false
    
    // Callback
    var onComplete: (() -> Void)?
    
    var body: some View {
        ZStack {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack {
                // Progress Bar
                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(index <= currentStep ? Color.appGreenMain : Color.gray.opacity(0.3))
                            .frame(height: 6)
                            .animation(.spring(), value: currentStep)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                // Content
                TabView(selection: $currentStep) {
                    // Step 1: Identity
                    PetIdentityView(name: $name, ownerNickname: $ownerName, profile: $profile)
                        .tag(0)
                    
                    // Step 2: Personality
                    PetPersonalityView(personality: $profile.personality)
                        .tag(1)
                    
                    // Step 3: Voice
                    PetVoiceView(voiceStyle: $profile.voiceStyle)
                        .tag(2)
                    
                    // Step 3.5: Summary / Certificate
                    PetCertificateView(name: name, ownerName: ownerName, profile: profile)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation Buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button {
                            withAnimation {
                                currentStep -= 1
                            }
                        } label: {
                            Text("上一步")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.gray)
                                .cornerRadius(24)
                                .shadow(radius: 2)
                        }
                    }
                    
                    Button {
                        if currentStep < 3 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            completeSetup()
                        }
                    } label: {
                        Text(currentStep < 3 ? "下一步" : "完成领养")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appGreenMain)
                            .foregroundColor(.white)
                            .cornerRadius(24)
                            .shadow(radius: 4)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
        }
        .onAppear {
            loadInitialData()
        }
        .navigationTitle("宠物档案")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Logic
    
    private func loadInitialData() {
        let userData = DataManager.shared.userData
        // Only load if not empty, otherwise default
        if !userData.petName.isEmpty { self.name = userData.petName }
        if !userData.ownerNickname.isEmpty { self.ownerName = userData.ownerNickname }
        self.profile = userData.petProfile
    }
    
    private func completeSetup() {
        var userData = DataManager.shared.userData
        userData.petName = name.trimmingCharacters(in: .whitespaces)
        if userData.petName.isEmpty { userData.petName = "狗狗" }
        
        userData.ownerNickname = ownerName.trimmingCharacters(in: .whitespaces)
        if userData.ownerNickname.isEmpty { userData.ownerNickname = "主人" }
        
        // Ensure breed is not empty, as PetWalkApp uses this to check if profile is set
        var finalProfile = profile
        if finalProfile.breed.trimmingCharacters(in: .whitespaces).isEmpty {
            finalProfile.breed = "混血小可爱"
        }
        userData.petProfile = finalProfile
        userData.hasCompletedOnboarding = true
        
        print("💾 Saving Profile: Breed=\(finalProfile.breed)")
        DataManager.shared.updateUserData(userData)
        
        // Trigger generic completion
        onComplete?()
    }
}

// MARK: - Certificate View (Summary)

struct PetCertificateView: View {
    let name: String
    let ownerName: String
    let profile: PetProfile
    @ObservedObject private var petViewModel = PetViewModel.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎉 领养证书")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.appBrown)
            
            VStack(spacing: 16) {
                ZStack {
                    if let petImage = petViewModel.currentPetImage {
                        Image(uiImage: petImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.appGreenMain, lineWidth: 3)
                            )
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "dog.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.appBrown)
                    }
                    
                    // Gender badge
                    if profile.gender != .unknown {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 32, height: 32)
                                    .shadow(radius: 2)
                                    .overlay(
                                        Text(profile.gender.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(profile.gender == .male ? .blue : .pink)
                                    )
                            }
                        }
                    }
                }
                .frame(width: 120, height: 120)
                
                Text(name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("品种: \(profile.breed.isEmpty ? "混血小可爱" : profile.breed)")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Divider()
                
                HStack(alignment: .top, spacing: 30) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("性格标签:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(profile.personality.traitsDescription)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI 语气:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(profile.voiceStyle.rawValue)
                            .font(.body)
                            .padding(4)
                            .background(Color.appGreenMain.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Divider()
                
                Text("监护人: \(ownerName)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Text("From: \(Date().formatted(date: .long, time: .omitted))")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 40)
    }
}
