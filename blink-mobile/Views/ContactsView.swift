//
//  ContactsView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

struct ContactsView: View {
    @State private var contacts: [ContactInfo] = []
    
    var body: some View {
        NavigationView {
            List {
                if contacts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No contacts yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("When you and someone both like each other during a call, you'll see their contact info here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(contacts) { contact in
                        ContactRow(contact: contact)
                    }
                }
            }
            .navigationTitle("Contacts")
        }
    }
}

struct ContactRow: View {
    let contact: ContactInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(contact.name)
                .font(.headline)
            
            Text(contact.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let phone = contact.phoneNumber {
                HStack {
                    Image(systemName: "phone.fill")
                    Text(phone)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContactsView()
} 