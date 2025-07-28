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
    static let supabaseURL = "https://kaqmpysdqsgxeyvufnne.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImthcW1weXNkcXNneGV5dnVmbm5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMzQyMTMsImV4cCI6MjA2ODgxMDIxM30.sRnbxnBwl3IzVoQoQuGfWcw6y_zv_DPrD1yfd_0zw-U"
    
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
