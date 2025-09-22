//
//  AccountSettingsScreen.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

struct AccountSettingsScreen: View {
    @ObservedObject var context: AccountSettingsScreenViewModel.Context
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case username, password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header section
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.onBackground)
                    
                    VStack(spacing: 8) {
                        Text("Add Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Sign in to book resources and register for events at your university")
                            .font(.subheadline)
                            .foregroundColor(.onBackground)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                
                // Form section
                VStack(spacing: 16) {
                    // Username field
                    HStack {
                        Image(systemName: "person")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.onSurface.opacity(0.75))
                            .padding(.trailing, 5)
                        
                        TextField("Username", text: .init(
                            get: { context.viewState.username },
                            set: { context.send(viewAction: .updateUsername($0)) }
                        ))
                        .font(.bodyMedium)
                        .foregroundColor(.onSurface)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .username)
                        
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.surface)
                    .cornerRadius(15)
                    
                    // Password field
                    HStack {
                        Image(systemName: "lock")
                            .font(.bodyMedium)
                            .foregroundColor(.onSurface.opacity(0.75))
                            .padding(.trailing, .spacingXS)
                        
                        SecureField("Password", text: .init(
                            get: { context.viewState.password },
                            set: { context.send(viewAction: .updatePassword($0)) }
                        ))
                        .font(.bodyMedium)
                        .foregroundColor(.onSurface)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        
                        Spacer()
                    }
                    .padding(.paddingS)
                    .background(Color.surface)
                    .cornerRadius(.radiusL)
                    
                    Picker("School", selection: .init(
                        get: { context.viewState.selectedSchool },
                        set: { context.send(viewAction: .updateSchool($0)) }
                    )) {
                        Text("Select your school").tag("")
                        ForEach(allSchools, id: \.id) { school in
                            Text(school.name).tag(school.id)
                        }
                    }
                    .font(.bodyMedium)
                    .foregroundColor(.onSurface)
                    
                    // Sign in button
                    Button {
                        context.send(viewAction: .login)
                    } label: {
                        HStack {
                            if context.viewState.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(context.viewState.isLoading ? "Signing in..." : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            context.viewState.isFormValid && !context.viewState.isLoading
                                ? Color.primary
                                : Color.surface.opacity(0.5)
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: .radiusL))
                    }
                    .disabled(!context.viewState.isFormValid || context.viewState.isLoading)
                    .padding(.top, .spacingXS)
                }
                .padding(.horizontal, .spacingXL)
                
                Spacer()
            }
        }
        .background(Color.background)
        .alert("Sign In Failed", isPresented: .constant(context.viewState.error != nil)) {
            Button("OK") {
                context.send(viewAction: .dismissError)
            }
        } message: {
            if let error = context.viewState.error {
                Text(error)
            }
        }
        .onSubmit {
            switch focusedField {
            case .username:
                focusedField = .password
            case .password:
                if context.viewState.isFormValid {
                    context.send(viewAction: .login)
                }
            case .none:
                break
            }
        }
    }
}
