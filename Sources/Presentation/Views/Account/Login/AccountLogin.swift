//
//  AccountLogin.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-12.
//

import SwiftUI

enum FocusedField {
    case username
    case password
}

struct AccountLogin: View {
    let isAddAccount: Bool
    @ObservedObject var viewModel: LoginViewModel = .init()
    @ObservedObject var appController: AppController = .shared
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var visiblePassword: Bool = false
    @State private var selectedSchool: School? = nil
    
    @FocusState private var focusedField: FocusedField?

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color.background // Ensure background covers the full area
                    .ignoresSafeArea() // Allow tapping outside the content to dismiss the keyboard
                
                VStack(alignment: .leading) {
                    LoginHeader(isAddAccount: isAddAccount)
                    VStack(spacing: Spacing.extraLarge) {
                        HStack {
                            schoolSelectionMenu
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        VStack {
                            UsernameField(username: $username)
                                .focused($focusedField, equals: .username)
                            PasswordField(password: $password, visiblePassword: $visiblePassword)
                                .focused($focusedField, equals: .password)
                        }
                        if viewModel.attemptingLogin {
                            CustomProgressIndicator()
                                .padding(.top, 15)
                        } else {
                            LoginButton(login: login, username: $username, password: $password)
                        }
                    }
                    .padding(.horizontal, Spacing.medium)
                    
                    Spacer()
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.top, 55)
                .contentShape(Rectangle()) // This allows the whole area to be tappable
                .onTapGesture {
                    // Dismiss the keyboard by unfocusing the fields
                    focusedField = nil
                }
            }
        }
    }
    
    var schoolSelectionMenu: some View {
        Menu {
            ForEach(viewModel.schools, id: \.self) { school in
                Button(action: {
                    selectedSchool = school
                    setSchoolForAuth()
                }, label: {
                    HStack {
                        Text(school.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.onBackground)
                        if school == selectedSchool {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.onBackground)
                        }
                    }
                })
            }
        } label: {
            HStack {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(selectedSchool?.name ?? NSLocalizedString("Select university", comment: ""))
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }
    
    fileprivate func login() {
        if let selectedSchool = selectedSchool {
            Task {
                await viewModel.login(
                    authSchoolId: selectedSchool.id,
                    username: username,
                    password: password
                )
            }
        } else { /// No school selected, invalid
            PopupToast(popup: PopupFactory.shared.loginRequiresSchool()).showAndStack()
        }
    }
    
    fileprivate func setSchoolForAuth() {
        if let selectedSchool = selectedSchool {
            viewModel.setDefaultAuthSchool(schoolId: selectedSchool.id)
        }
    }
}
