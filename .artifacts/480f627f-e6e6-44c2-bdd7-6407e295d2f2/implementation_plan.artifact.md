# Implement AI Risk Assistant

This plan outlines the steps to build a functional AI-powered chat assistant within the RiskPulse app. The assistant will leverage Google's Gemini Pro model to provide users with disaster risk intelligence, safety advice, and data interpretation.

## User Review Required

> [!IMPORTANT]
> **API Key Management**: This implementation requires a Gemini API Key. For this plan, I will implement a way to provide it via a service configuration, but in a production app, this should be handled via secure environment variables or a backend proxy.

## Proposed Changes

### Core Infrastructure

#### [MODIFY] [pubspec.yaml](file:///C:/Users/HP/StudioProjects/riskpulse/pubspec.yaml)
Add `google_generative_ai` for LLM integration and `flutter_markdown` for response formatting.

#### [NEW] [chat_message.dart](file:///C:/Users/HP/StudioProjects/riskpulse/lib/data/models/chat_message.dart)
Define a simple data model for chat bubbles (user vs. AI).

#### [NEW] [ai_assistant_service.dart](file:///C:/Users/HP/StudioProjects/riskpulse/lib/data/services/ai_assistant_service.dart)
Implement the service to interact with the Gemini API, including system prompt definitions.

### UI Components

#### [MODIFY] [ai_assistant_screen.dart](file:///C:/Users/HP/StudioProjects/riskpulse/lib/screens/ai_assistant/ai_assistant_screen.dart)
Replace the placeholder with a stateful chat interface including a message list and input field.

## Verification Plan

### Manual Verification
- Verify that the chat UI scrolls correctly as new messages are added.
- Test the "thinking" state when waiting for an AI response.
- (Requires API Key) Verify that the AI provides relevant disaster risk advice based on the system prompt.
