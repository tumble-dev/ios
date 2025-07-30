//
//  SignOutButton.swift
//  Tumble
//
//  Created by Adis Veletanlic on 6/14/23.
//

import SwiftUI

struct SignOutButton: View {
    
    let showConfirmationDialog: () -> Void
    
    var body: some View {
        Button(action: showConfirmationDialog, label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .actionIcon()
        })
    }
}

