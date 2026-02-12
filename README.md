# Moula (iOS)

This repository contains an iOS app built with Xcode / SwiftUI.

## Requirements

- macOS with Xcode installed (latest stable recommended)

## Getting started (run on Simulator)

1. Clone the repo:

```bash
git clone https://github.com/<YOUR_USERNAME>/<YOUR_REPO>.git
cd "<YOUR_REPO>"
```

2. Open the project in Xcode:

- Open `OnboardingApp.xcodeproj`

3. In Xcode:

- Select an iPhone Simulator (top toolbar)
- Press **Run** (or `Cmd + R`)

## Running on a physical device

To run on an iPhone, you’ll typically need to set up signing:

- Xcode → Project settings → **Signing & Capabilities**
- Select your **Team**
- If needed, change the **Bundle Identifier** to something unique for your Apple ID

## Troubleshooting

- If the project opens but won’t build, try:
  - Xcode → Product → **Clean Build Folder**
  - Xcode → Settings → Locations → Derived Data → **Delete**

