apt install unzip
curl -fsSL https://opencode.ai/install | bash

{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://<server>:11434/v1"
      },
      "models": {
        "llama3.2:3b": {
          "name": "default"
        }
      }
    }
  },
  "model": "ollama/default"
}