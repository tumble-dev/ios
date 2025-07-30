//
//  User.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-13.
//

import SwiftUI

struct UserOverview: View {
    @ObservedObject var viewModel: AccountViewModel
    @ObservedObject var appController: AppController = .shared
        
    @State private var collapsedHeader: Bool = false
    @State private var isSelecting: Bool = false
    @State private var isNavigatingToAddAccount: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.medium) {
                UserHeader(collapsedHeader: $collapsedHeader, viewModel: viewModel)
                if isSelecting {
                    Divider()
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        ForEach(viewModel.users, id:\.username) { user in
                            UserOptionView(user: user, viewModel: viewModel) {
                                withAnimation(.easeInOut) {
                                    isSelecting = false
                                    HapticsController.triggerHapticLight()
                                    Task {
                                        await viewModel.setCurrentUser(to: user.username)
                                    }
                                }
                            }
                        }
                        Button {
                            withAnimation(.easeInOut) {
                                isNavigatingToAddAccount = true
                                isSelecting = false
                            }
                        } label: {
                            HStack {
                                Text(NSLocalizedString("Add account", comment: ""))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.onPrimary)
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.onPrimary)
                            }
                            .padding(10)
                            .background(Color.primary)
                            .cornerRadius(15)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.medium)
            .background(Color.surface)
            .cornerRadius(10)
            .padding([.horizontal, .top], Spacing.medium)
            .onTapGesture {
                if viewModel.users.count > 1 {
                    withAnimation(.easeInOut) {
                        isSelecting.toggle()
                    }
                } else {
                    isNavigatingToAddAccount = true
                }
            }
            Divider()
                .foregroundColor(.onBackground)
                .padding(.top, Spacing.medium)
            Resources(
                parentViewModel: viewModel,
                getResourcesAndEvents: viewModel.getResourcesAndEvents,
                collapsedHeader: $collapsedHeader
            )
        }
        .background(Color.background)
        .background(
            NavigationLink(
                destination: AccountLogin(isAddAccount: true),
                isActive: $isNavigatingToAddAccount
            ) {
                EmptyView()
            }
        )
        .onChange(of: viewModel.currentUser) { newValue in
            isNavigatingToAddAccount = false
            viewModel.getResourcesAndEvents()
        }
    }
}
