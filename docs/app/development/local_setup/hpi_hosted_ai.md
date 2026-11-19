# Configure HPI-hosted AI models

This guide explains how to use HPI-hosted language models with GitHub Copilot Chat and OpenCode.

!!! note
    This feature is experimental and subject to change.
    Available models and configuration options may change over time.
    Model availability is not guaranteed.

## Create an API key

1. Open [101010.hpi.de](https://101010.hpi.de/).
2. Navigate to Settings → Account → API keys.
3. Create a new API key.
4. Copy the key. You will use it when configuring your AI client.

## GitHub Copilot Chat

### Add the custom model

Follow the [GitHub Copilot documentation on custom endpoints](https://code.visualstudio.com/docs/agent-customization/language-models#_add-a-custom-endpoint-model) to add a custom model.
Select "Chat Completions" as the API type.

The following configuration is a starting point — adjust token limits and other settings as needed:

```json
{
  "id": "HPI-Intern-Qwen3.6-35B-A3B",
  "name": "HPI Qwen 3.6 35B",
  "url": "https://101010.hpi.de/api/v1/chat/completions",
  "apiType": "chat-completions",
  "toolCalling": true,
  "vision": false,
  "thinking": true,
  "streaming": true,
  "maxInputTokens": 229376,
  "maxOutputTokens": 32768
},
{
  "id": "HPI-Intern-Qwen38-27B",
  "name": "HPI Qwen 3.8 27B",
  "url": "https://101010.hpi.de/api/v1/chat/completions",
  "apiType": "chat-completions",
  "toolCalling": true,
  "vision": true,
  "thinking": true,
  "streaming": true,
  "maxInputTokens": 467232,
  "maxOutputTokens": 32768,
  "supportsReasoningEffort": ["low", "medium"],
  "reasoningEffortFormat": "chat-completions"
},
```

### Start using the model

Select the configured model from the model picker in GitHub Copilot Chat.

## OpenCode

OpenCode can use the same HPI endpoint. Add the following configuration to your OpenCode configuration file:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": true,

  "provider": {
    "hpi": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "HPI",
      "options": {
        "baseURL": "https://101010.hpi.de/api/v1"
      },
      "models": {
        "HPI-Intern-Qwen3.6-35B-A3B": {
          "name": "HPI Qwen 3.6"
        },
        "HPI-Intern-Qwen38-27B": {
          "name": "HPI Qwen 3.8",

          "reasoning": true,

          "interleaved": {
            "field": "reasoning_content"
          },

          "variants": {
            "low": {
              "reasoningEffort": "low"
            },
            "medium": {
              "reasoningEffort": "medium"
            }
          }
        }
      }
    }
  },

  "enabled_providers": ["hpi"],
  "model": "hpi/HPI-Intern-Qwen38-27B"
}
```
