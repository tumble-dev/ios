//
//  AuthState.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-11-14.
//


enum AuthState {
    case connected(user: TumbleUser)
    case disconnected
    case error(msg: String)
    case loading
}
