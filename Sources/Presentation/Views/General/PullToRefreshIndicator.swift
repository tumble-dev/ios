//
//  PullToRefreshIndicator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 4/1/23.
//

import SwiftUI

struct PullToRefreshIndicator: View {
    var body: some View {
        HStack {
            Text(NSLocalizedString("Pull to refresh", comment: ""))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            Image(systemName: "arrow.down")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct PullToRefreshIndicator_Previews: PreviewProvider {
    static var previews: some View {
        PullToRefreshIndicator()
    }
}
