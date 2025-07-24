//
//  SupabaseConfig.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//

import Foundation
import Supabase

class SupabaseConfig {
    // MARK: - Configuration
    static let supabaseURL = ""
    static let supabaseAnonKey = ""
    
    // MARK: - Supabase Client
    static let client = SupabaseClient(
        supabaseURL: URL(string: supabaseURL)!,
        supabaseKey: supabaseAnonKey
    )
    
    // MARK: - Validation
    static func validateConfiguration() -> Bool {
        let isValidURL = !supabaseURL.contains("YOUR_SUPABASE_URL")
        let isValidKey = !supabaseAnonKey.contains("YOUR_SUPABASE_ANON_KEY")
        
        if !isValidURL || !isValidKey {
            print("⚠️ Please update SupabaseConfig.swift with your actual Supabase credentials")
            return false
        }
        
        return true
    }
} 
