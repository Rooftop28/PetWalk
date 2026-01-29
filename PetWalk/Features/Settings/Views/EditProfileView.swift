//
//  EditProfileView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/29.
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var petName: String = ""
    @State private var ownerNickname: String = ""
    @State private var showCostAlert = false
    @State private var showInsufficientFundsAlert = false
    
    // 修改资料消耗的骨头币
    private let editCost = 100
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("当前骨头币")
                        Spacer()
                        Text("\(dataManager.userData.totalBones)")
                            .font(.headline)
                            .foregroundColor(.appBrown)
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.appBrown)
                    }
                } header: {
                    Text("余额")
                }
                
                Section {
                    HStack {
                        Text("宠物名字")
                        Spacer()
                        TextField("例如：旺财", text: $petName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("主人称呼")
                        Spacer()
                        TextField("例如：爸爸", text: $ownerNickname)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("修改信息")
                } footer: {
                    Text("设置你对宠物的称呼，以及宠物对你的称呼。\n修改资料需要消耗 \(editCost) 骨头币。")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("修改称呼")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        validateAndSave()
                    }
                    .disabled(petName.isEmpty || ownerNickname.isEmpty || (petName == dataManager.userData.petName && ownerNickname == dataManager.userData.ownerNickname))
                    .foregroundColor(.appGreenMain)
                }
            }
            .onAppear {
                petName = dataManager.userData.petName
                ownerNickname = dataManager.userData.ownerNickname
            }
            .alert("确认修改", isPresented: $showCostAlert) {
                Button("支付 \(editCost) 骨头币", role: .destructive) {
                    performSave()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("修改资料将消耗 \(editCost) 骨头币，确定要继续吗？")
            }
            .alert("余额不足", isPresented: $showInsufficientFundsAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("你的骨头币不足 \(editCost) 枚，多去遛狗赚取吧！")
            }
        }
    }
    
    private func validateAndSave() {
        if dataManager.userData.totalBones >= editCost {
            showCostAlert = true
        } else {
            showInsufficientFundsAlert = true
        }
    }
    
    private func performSave() {
        var userData = dataManager.userData
        userData.totalBones -= editCost
        userData.petName = petName.trimmingCharacters(in: .whitespaces)
        userData.ownerNickname = ownerNickname.trimmingCharacters(in: .whitespaces)
        dataManager.updateUserData(userData)
        dismiss()
    }
}

#Preview {
    EditProfileView()
}
