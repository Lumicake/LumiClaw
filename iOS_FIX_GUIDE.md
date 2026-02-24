# iOS Build Errors - Complete Fix

## Errors to Fix in `/Users/osmond/Lumi/LumiAgent/App/iOSMainView.swift`

### Error 1: Line 107 - Temperature Double unwrapping
**Current (broken):**
```swift
LabeledContent("Temperature", value: agent.configuration.temperature)
```

**Fixed:**
```swift
LabeledContent("Temperature", value: String(format: "%.1f", agent.configuration.temperature))
```

### Error 2: Line 145 - Title String unwrapping
**Current (broken):**
```swift
Text(conversation.title)
```

**Fixed:**
```swift
Text(conversation.title ?? "Conversation")
```

Or if it's in the chat view:
```swift
.navigationTitle(conversation?.title ?? "Chat")
```

### Error 3: Line 218 - Color blue type mismatch
**Current (broken):**
```swift
.background(message.role == .user ? Color.blue : Color(.systemGray5))
```

**Fixed:**
```swift
.background(message.role == .user ? Color.blue : Color(uiColor: .systemGray5))
```

---

## Complete Fixed MessageBubble (replace lines ~210-240):

```swift
struct MessageBubble: View {
    let message: SpaceMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(uiColor: .systemGray5))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if message.isStreaming {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            if message.role != .user {
                Spacer()
            }
        }
    }
}
```

---

## Complete Fixed iOSAgentDetailView (replace lines ~95-125):

```swift
struct iOSAgentDetailView: View {
    let agent: Agent
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section("Configuration") {
                LabeledContent("Provider", value: agent.configuration.provider.rawValue)
                LabeledContent("Model", value: agent.configuration.model)
                LabeledContent("Temperature", value: String(format: "%.1f", agent.configuration.temperature))
            }
            
            Section("System Prompt") {
                if let prompt = agent.configuration.systemPrompt {
                    Text(prompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No system prompt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Text("⚠️ Tool execution is only available on macOS")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("To use tools like file operations, terminal commands, and system automation, please use LumiAgent on your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Tools")
            }
        }
        .navigationTitle(agent.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

---

## Complete Fixed iOSConversationsView (replace lines ~135-175):

```swift
struct iOSConversationsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingNewConversation = false
    
    var body: some View {
        List {
            ForEach(appState.conversations) { conversation in
                NavigationLink {
                    iOSChatView(conversationId: conversation.id)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conversation.title ?? "Conversation")
                            .font(.headline)
                        if let lastMessage = conversation.messages.last {
                            Text(lastMessage.content)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .toolbar {
            Button {
                showingNewConversation = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingNewConversation) {
            iOSNewConversationView()
        }
        .overlay {
            if appState.conversations.isEmpty {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "message",
                    description: Text("Start a new conversation with your agents")
                )
            }
        }
    }
}
```

---

## Quick Search & Replace Instructions

### In Xcode:

1. **Open** `/Users/osmond/Lumi/LumiAgent/App/iOSMainView.swift`

2. **Fix Error 1** - Press `⌘F`, search for:
   ```
   LabeledContent("Temperature", value: agent.configuration.temperature)
   ```
   Replace with:
   ```
   LabeledContent("Temperature", value: String(format: "%.1f", agent.configuration.temperature))
   ```

3. **Fix Error 2** - Search for:
   ```
   Text(conversation.title)
   ```
   Replace with:
   ```
   Text(conversation.title ?? "Conversation")
   ```

4. **Fix Error 3** - Search for:
   ```
   Color(.systemGray5)
   ```
   Replace with:
   ```
   Color(uiColor: .systemGray5)
   ```

5. **Save** the file (`⌘S`)

6. **Clean Build** (`⌘⇧K`)

7. **Build** (`⌘B`)

---

## All Key Type Differences for iOS:

| macOS | iOS | Why |
|-------|-----|-----|
| `Color(.systemGray5)` | `Color(uiColor: .systemGray5)` | UIKit vs AppKit |
| `Optional<Double>` in LabeledContent | Must be String | Type requirement |
| `Optional<String>` in Text/titles | Must unwrap with `??` | Type requirement |
| `URL(string: "...")!` | `if let url = URL(...)` | No force unwrap |

---

## After Fixing

Run:
```
⌘⇧K (Clean)
⌘B (Build)
```

You should see: **Build Succeeded** ✅
