//
//  ProfileView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = profileViewModel.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.pink)
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Account") {
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    profileViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// #Preview {
//     let profileViewModel = ProfileViewModel(authService: MockAuthService.shared)
//     return ProfileView().environmentObject(profileViewModel)
// } 