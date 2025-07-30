//
//  Contributors.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import SwiftUI
import Foundation

struct Contributors: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack {
            switch viewModel.contributorPageStatus {
            case .loading:
                VStack {
                    CustomProgressIndicator()
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 200,
                    maxHeight: .infinity,
                    alignment: .center
                )
            case .error:
                Info(title: NSLocalizedString("Could not contact the server, try again later", comment: ""), image: nil)
            case .loaded:
                ScrollView {
                    ForEach(viewModel.contributors, id: \.id) { contributor in
                        ContributorRow(contributor: contributor)
                    }
                    .padding()
                }
            }
        }
        .background(Color.background)
        .onAppear {
            viewModel.getRepoContributors()
        }
        .onDisappear {
            viewModel.cancelContributorFetch()
        }
    }
}

struct ContributorRow: View {
    let contributor: Contributor
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: contributor.avatarURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView()
            }
            VStack(alignment: .leading) {
                Text(contributor.login)
                    .font(.headline)
                    .foregroundColor(.onSurface)
                Text(String(format: NSLocalizedString("%@ contributions", comment: ""), String(contributor.contributions)))
                    .font(.subheadline)
                    .foregroundColor(.onSurface.opacity(0.8))
                Link(NSLocalizedString("View Profile", comment: ""), destination: URL(string: contributor.htmlURL)!)
                    .font(.footnote)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(8)
    }
}
