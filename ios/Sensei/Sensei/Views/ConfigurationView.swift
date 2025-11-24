//
//  ConfigurationView.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//


import SwiftUI

struct ConfigurationView: View {
    @ObservedObject var configManager: ConfigurationManager
    @State private var tempServerURL: String = ""
    @State private var tempToken: String = ""
    @State private var showingToken = false
    @State private var validationMessage: String = ""
    @State private var isValidating = false
    @State private var serverChecked = false
    @State private var tokenChecked = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Server Configuration")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server addreess")
                        .font(.headline)
                    TextField("http://domain.com:1234", text: $tempServerURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Authorization Token")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            showingToken.toggle()
                        }) {
                            Image(systemName: showingToken ? "eye.slash" : "eye")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if showingToken {
                        TextField("Enter token", text: $tempToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        SecureField("Enter token", text: $tempToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section {
                Button(action: checkConfiguration) {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(isValidating ? "Checking..." : "Check Configuration")
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(isValidConfiguration && !isValidating ? Color.blue : Color.gray)
                    .cornerRadius(10)
                }
                .disabled(!isValidConfiguration || isValidating)
                
                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(serverChecked && tokenChecked ? .green : .red)
                        .padding(.top, 4)
                }
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    configManager.saveConfiguration(serverURL: tempServerURL, token: tempToken)
                    dismiss()
                }
                .disabled(!serverChecked || !tokenChecked)
            }
        }
        .onAppear {
            tempServerURL = configManager.currentConfiguration?.serverURL ?? ""
            tempToken = configManager.currentConfiguration?.token ?? ""
        }
    }
    
    private var isValidConfiguration: Bool {
        !tempServerURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !tempToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func checkConfiguration() {
        isValidating = true
        validationMessage = ""
        serverChecked = false
        tokenChecked = false
        
        // Step 1: Check server is up
        checkServerUp { serverSuccess in
            if serverSuccess {
                validationMessage = "Server is running."
                serverChecked = true
                
                // Step 2: Check token authentication
                checkTokenAuthentication { tokenSuccess in
                    isValidating = false
                    if tokenSuccess {
                        validationMessage += " Authentication token is correct."
                        tokenChecked = true
                    } else {
                        validationMessage = "Token invalid, authentication failed. Please check it out."
                        tokenChecked = false
                    }
                }
            } else {
                isValidating = false
                validationMessage = "Server is not reachable. Please check the address."
                serverChecked = false
            }
        }
    }
    
    private func checkServerUp(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: tempServerURL.trimmingCharacters(in: .whitespacesAndNewlines) + "/up") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    private func checkTokenAuthentication(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: tempServerURL.trimmingCharacters(in: .whitespacesAndNewlines) + "/sensors/") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tempToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true)
                    } else if httpResponse.statusCode == 401 {
                        completion(false)
                    } else {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
}
