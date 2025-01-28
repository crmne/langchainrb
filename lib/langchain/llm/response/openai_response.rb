# frozen_string_literal: true

module Langchain::LLM
  class OpenAIResponse < BaseResponse
    def model
      raw_response["model"]
    end

    def created_at
      if raw_response.dig("created")
        Time.at(raw_response.dig("created"))
      end
    end

    def completion
      completions&.dig(0, "message", "content")
    end

    def role
      completions&.dig(0, "message", "role")
    end

    def chat_completion
      completion
    end

    def tool_calls
      if chat_completions.dig(0, "message").has_key?("tool_calls")
        chat_completions.dig(0, "message", "tool_calls")
      else
        []
      end
    end

    def embedding
      embeddings&.first
    end

    def completions
      raw_response.dig("choices")
    end

    def chat_completions
      raw_response.dig("choices")
    end

    def embeddings
      raw_response.dig("data")&.map { |datum| datum.dig("embedding") }
    end

    def prompt_tokens
      raw_response.dig("usage", "prompt_tokens")
    end

    def completion_tokens
      raw_response.dig("usage", "completion_tokens")
    end

    def total_tokens
      raw_response.dig("usage", "total_tokens")
    end

    # List models
    def format_display_name(model_id)
      name = model_id.tr("-", " ").titleize

      name.gsub(/(\d{4}) (\d{2}) (\d{2})/, '\1\2\3')  # Convert dates to YYYYMMDD
          .gsub(/^Gpt /, "GPT-")
          .gsub(/^O1 /, "O1-")
          .gsub(/^Chatgpt /, "ChatGPT-")
          .gsub(/^Tts /, "TTS-")
          .gsub(/^Dall E /, "DALL-E-")
          .gsub(/3\.5 /, "3.5-")
          .gsub(/4 /, "4-")
          .gsub(/4o (?=Mini|Preview|Turbo)/, "4o-")
          .gsub(/\bHd\b/, "HD")
    end

    def model_ids
      models.map(&:id)
    end

    def created_dates
      models.map(&:created_at)
    end

    def display_names
      models.map(&:display_name)
    end

    def provider
      "OpenAI"
    end

    def models
      raw_response.dig("data")&.map do |model|
        ModelInfo.new(
          id: model["id"],
          created_at: Time.at(model["created"]),
          display_name: format_display_name(model["id"]),
          provider: "openai",
          metadata: {
            object: model["object"],
            owned_by: model["owned_by"]
          },
          context_window: determine_context_window(model["id"]),
          max_tokens: determine_max_tokens(model["id"]),
          supports_vision: supports_vision?(model["id"]),
          supports_functions: supports_functions?(model["id"]),
          supports_json_mode: supports_json_mode?(model["id"]),
          input_price_per_1k: get_input_price(model["id"]),
          output_price_per_1k: get_output_price(model["id"])
        )
      end || []
    end

    private

    def determine_context_window(model_id)
      case model_id
      when /gpt-4o/, /o1/, /gpt-4-turbo/
        128_000
      when /gpt-4-0[0-9]{3}/ # older GPT-4 models
        8_192
      when /gpt-3.5-turbo-instruct/
        4_096
      when /gpt-3.5/
        16_385
      else
        4_096
      end
    end

    def determine_max_tokens(model_id)
      case model_id
      when /o1-2024-12-17/
        100_000
      when /o1-mini-2024-09-12/
        65_536
      when /o1-preview-2024-09-12/
        32_768
      when /gpt-4o/, /gpt-4-turbo/
        16_384
      when /gpt-4-0[0-9]{3}/ # older GPT-4 models
        8_192
      when /gpt-3.5-turbo/
        4_096
      else
        4_096
      end
    end

    def get_input_price(model_id)
      case model_id
      when /o1-2024/
        0.015   # $15.00 per million tokens
      when /o1-mini/
        0.003   # $3.00 per million tokens
      when /gpt-4o-realtime-preview/
        0.005   # $5.00 per million tokens
      when /gpt-4o-mini-realtime-preview/
        0.0006  # $0.60 per million tokens
      when /gpt-4o-mini/
        0.00015 # $0.15 per million tokens
      when /gpt-4o/
        0.0025  # $2.50 per million tokens
      when /gpt-4-turbo/
        0.01    # $0.01 per 1k tokens
      when /gpt-3.5/
        0.0005  # $0.0005 per 1k tokens
      else
        0.0005  # Default to GPT-3.5 pricing
      end
    end

    def get_output_price(model_id)
      case model_id
      when /o1-2024/
        0.06    # $60.00 per million tokens
      when /o1-mini/
        0.012   # $12.00 per million tokens
      when /gpt-4o-realtime-preview/
        0.02    # $20.00 per million tokens
      when /gpt-4o-mini-realtime-preview/
        0.0024  # $2.40 per million tokens
      when /gpt-4o-mini/
        0.0006  # $0.60 per million tokens
      when /gpt-4o/
        0.01    # $10.00 per million tokens
      when /gpt-4-turbo/
        0.03    # $0.03 per 1k tokens
      when /gpt-3.5/
        0.0015  # $0.0015 per 1k tokens
      else
        0.0015  # Default to GPT-3.5 pricing
      end
    end

    def supports_functions?(model_id)
      !model_id.include?("instruct")
    end

    def supports_vision?(model_id)
      model_id.include?("vision") || model_id.match?(/gpt-4-(?!0314|0613)/)
    end

    def supports_json_mode?(model_id)
      # Only newer models support JSON mode
      return true if model_id.match?(/gpt-4-\d{4}-preview/) ||
                     model_id.include?("turbo") ||
                     model_id.match?(/gpt-3.5-turbo-(?!0301|0613)/)
      false
    end
  end
end
