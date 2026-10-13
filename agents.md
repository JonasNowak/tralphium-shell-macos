# Tralphium Agent Guidelines

This document outlines the purpose, ambitions, and scope of the **Tralphium** project. AI agents working on this repository must read and adhere to these guidelines to ensure the project stays true to its core vision.

> **This is the macOS edition** (`tralphium-shell-macos`), a native Swift port of the Linux/Quickshell original. **Read [PLAN.md](PLAN.md) first**: it holds the architecture, the feature mapping, the cleanup list and the phases. Keep it up to date as work progresses (tick off phases, record decisions and limitations).

## 1. Purpose
The primary goal of Tralphium is to build a custom, fully functional desktop shell/GUI that runs on top of **macOS** (the Linux original targets Mango WM). 
- AI agents are tasked with the active implementation and maintenance of this shell. 
- The target state is a complete, stable, and daily-drivable graphical user interface tailored for the user.

## 2. Ambitions
Tralphium aims to compose a **fully featured yet lightweight GUI** that integrates seamlessly with macOS. 
- It should provide all the necessary desktop components (e.g., application launchers, taskbars, status areas) without unnecessary bloat.
- The project is not just a toy or a proof of concept; it is intended to reach a "finished" and polished state.

## 3. Scope & Philosophy
All code written, architectures proposed, and features implemented must strictly adhere to the following principles:
- **Lightweight:** Resource usage should be kept to a minimum (CPU and GPU). Event driven, no polling, no third-party dependencies, no over-engineered solutions.
- **KISS Philosophy (Keep It Simple, Stupid):** Simplicity is paramount. Code should be readable, straightforward, and maintainable. 
- **macOS Native:** The shell is built in Swift with AppKit and SwiftUI via SwiftPM (no Xcode project). Use public APIs first; load private ones only with `dlopen`/`dlsym` and a fallback. Do not reintroduce Qt, Quickshell, Wayland or other Linux-specific code.
- **Modularity:** Keep components logically separated (UI-free logic in `Sources/TralphiumCore/` with tests, app code in `Sources/Tralphium/`, helper scripts in `scripts/`) to ensure the codebase remains clean and simple to navigate.
