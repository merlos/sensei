import SwiftUI

struct ConfigurationView: View {
    @ObservedObject var configManager: ConfigurationManager
    @State private var tempServerURL: String = ""
    @State private var tempToken: String = ""
    @State private var showingToken = false
    
    var body: some View {
        Form {
            Section(header: Text("Server Configuration")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server URL")
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
                Button(action: {
                    configManager.saveConfiguration(serverURL: tempServerURL, token: tempToken)
                }) {
                    Text("Save Configuration")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(isValidConfiguration ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isValidConfiguration)
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
}