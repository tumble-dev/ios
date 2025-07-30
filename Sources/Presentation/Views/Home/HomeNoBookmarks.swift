//
//  HomeNoBookmarks.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-04.
//

import SwiftUI

struct HomeNoBookmarks: View {
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(NSLocalizedString("Looks like you don't have anything saved yet", comment: ""))
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.onBackground)
                    .padding(.bottom, 20)
                    .padding(.trailing, 10)
                Text(NSLocalizedString("Schedules are bookmarked from the search page, which you can access from the search tab.", comment: ""))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.onBackground)
                    .padding(.trailing, 30)
            }
            Spacer()
            Image("ManWaiting")
                .resizable()
                .scaledToFit()
                .frame(width: getRect().width - 40, height: getRect().width - 80)
        }
    }
}

struct HomeNoBookmarks_Previews: PreviewProvider {
    static var previews: some View {
        HomeNoBookmarks()
    }
}
