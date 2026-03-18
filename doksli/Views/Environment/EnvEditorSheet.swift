import SwiftUI

// MARK: - EnvEditorSheet

struct EnvEditorSheet: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedEnvId: UUID? = nil
    @State private var importError: String? = nil
    @State private var showImportError = false
    @State private var isConfirmingDelete = false

    var body: some View {
        HStack(spacing: 0) {
            envList
            Divider()
            detailEditor
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(AppColors.canvas)
        .alert("Import Error", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "Unknown error")
        }
        .alert("Delete Environment", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive) { deleteSelectedEnvironment() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this environment?")
        }
    }

    // MARK: - Environment list (left side)

    private var envList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ENVIRONMENTS")
                    .font(AppFonts.eyebrow)
                    .foregroundColor(AppColors.textFaint)
                    .tracking(1)
                Spacer()
                addEnvButton
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(appState.environments) { env in
                        envRow(env)
                    }
                }
            }
        }
        .frame(width: 180)
        .background(AppColors.surface)
    }

    private func envRow(_ env: Environment) -> some View {
        Button {
            selectedEnvId = env.id
        } label: {
            Text(env.name)
                .font(AppFonts.body)
                .foregroundColor(selectedEnvId == env.id ? AppColors.brand : AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(selectedEnvId == env.id ? AppColors.brandTint50 : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private var addEnvButton: some View {
        Button {
            let newEnv = Environment(id: UUID(), name: "New Environment", variables: [])
            appState.environments.append(newEnv)
            selectedEnvId = newEnv.id
            appState.saveEnvironments()
        } label: {
            Image(systemName: "plus")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail editor (right side)

    @ViewBuilder
    private var detailEditor: some View {
        if let index = selectedEnvIndex {
            VStack(spacing: 0) {
                detailHeader(at: index)
                Divider()
                variablesList(at: index)
                Divider()
                detailFooter
            }
        } else {
            VStack {
                Spacer()
                Text("Select or create an environment")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPlaceholder)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Detail header

    private func detailHeader(at index: Int) -> some View {
        HStack {
            TextField("Environment name", text: envNameBinding(at: index))
                .font(AppFonts.title)
                .textFieldStyle(.plain)

            Spacer()

            Button {
                isConfirmingDelete = true
            } label: {
                Image(systemName: "trash")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.errorText)
            }
            .buttonStyle(.plain)
            .help("Delete environment")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Variables list

    private func variablesList(at index: Int) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if index < appState.environments.count {
                    ForEach(appState.environments[index].variables) { envVar in
                        variableRow(envIndex: index, varId: envVar.id)
                        Divider().foregroundColor(AppColors.subtle)
                    }
                }
            }

            Button {
                guard index < appState.environments.count else { return }
                let newVar = EnvVar(id: UUID(), key: "", value: "", enabled: true)
                appState.environments[index].variables.append(newVar)
                appState.saveEnvironments()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "plus")
                    Text("Add Variable")
                }
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
            }
            .buttonStyle(.plain)
        }
    }

    private func variableRow(envIndex: Int, varId: UUID) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Toggle("", isOn: varBinding(envIndex: envIndex, varId: varId, keyPath: \.enabled))
                .toggleStyle(.checkbox)
                .labelsHidden()

            TextField("Key", text: varBinding(envIndex: envIndex, varId: varId, keyPath: \.key))
                .font(AppFonts.mono)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)

            TextField("Value", text: varBinding(envIndex: envIndex, varId: varId, keyPath: \.value))
                .font(AppFonts.mono)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)

            Button {
                guard envIndex < appState.environments.count else { return }
                appState.environments[envIndex].variables.removeAll { $0.id == varId }
                appState.saveEnvironments()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Footer

    private var detailFooter: some View {
        HStack {
            Button {
                importFromPostman()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import from Postman")
                }
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Done") {
                appState.showEnvEditor = false
            }
            .buttonStyle(.plain)
            .font(AppFonts.body)
            .foregroundColor(AppColors.brand)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.brandTint50)
            .cornerRadius(AppSpacing.radiusBadge)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Bindings

    private var selectedEnvIndex: Int? {
        guard let id = selectedEnvId else { return nil }
        return appState.environments.firstIndex(where: { $0.id == id })
    }

    private func envNameBinding(at index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < appState.environments.count else { return "" }
                return appState.environments[index].name
            },
            set: {
                guard index < appState.environments.count else { return }
                appState.environments[index].name = $0
                appState.saveEnvironments()
            }
        )
    }

    private func varBinding<T>(envIndex: Int, varId: UUID, keyPath: WritableKeyPath<EnvVar, T>) -> Binding<T> {
        Binding(
            get: {
                guard envIndex < appState.environments.count,
                      let vi = appState.environments[envIndex].variables.firstIndex(where: { $0.id == varId }) else {
                    return EnvVar(id: UUID(), key: "", value: "", enabled: true)[keyPath: keyPath]
                }
                return appState.environments[envIndex].variables[vi][keyPath: keyPath]
            },
            set: { newValue in
                guard envIndex < appState.environments.count,
                      let vi = appState.environments[envIndex].variables.firstIndex(where: { $0.id == varId }) else { return }
                appState.environments[envIndex].variables[vi][keyPath: keyPath] = newValue
                appState.saveEnvironments()
            }
        )
    }

    // MARK: - Actions

    private func deleteSelectedEnvironment() {
        guard let index = selectedEnvIndex else { return }
        let envId = appState.environments[index].id
        appState.environments.remove(at: index)
        if appState.activeEnvironment?.id == envId {
            appState.activeEnvironment = nil
        }
        selectedEnvId = nil
        appState.saveEnvironments()
    }

    private func importFromPostman() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let env = try PostmanImporter.importEnvironment(from: url)
            appState.environments.append(env)
            selectedEnvId = env.id
            appState.saveEnvironments()
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }
}
