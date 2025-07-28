//
//  BlinkModels.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation

// MARK: - Data Models

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
}

struct CallSession: Identifiable {
    let id = UUID()
    let partnerId: String
    let partnerName: String
    var isActive: Bool = true
}

struct ContactInfo: Identifiable, Codable {
    let id: UUID
    let name: String
    let email: String
    let phoneNumber: String?
    let instagramHandle: String?
    let tiktokHandle: String?
    let twitterHandle: String?
    let linkedinUrl: String?
} 