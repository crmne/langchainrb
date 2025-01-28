# frozen_string_literal: true

module Langchain::LLM
  class AnthropicResponse < BaseResponse
    def model
      raw_response.dig("model")
    end

    def completion
      completions.first
    end

    def chat_completion
      chat_completion = chat_completions.find { |h| h["type"] == "text" }
      chat_completion&.dig("text")
    end

    def tool_calls
      tool_call = chat_completions.find { |h| h["type"] == "tool_use" }
      tool_call ? [tool_call] : []
    end

    def chat_completions
      raw_response.dig("content")
    end

    def completions
      [raw_response.dig("completion")]
    end

    def stop_reason
      raw_response.dig("stop_reason")
    end

    def stop
      raw_response.dig("stop")
    end

    def log_id
      raw_response.dig("log_id")
    end

    def prompt_tokens
      raw_response.dig("usage", "input_tokens").to_i
    end

    def completion_tokens
      raw_response.dig("usage", "output_tokens").to_i
    end

    def total_tokens
      prompt_tokens + completion_tokens
    end

    def role
      raw_response.dig("role")
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
      "Anthropic"
    end

    # List models
    def models
      return [] unless raw_response.is_a?(Array)

      raw_response.map do |model|
        ModelInfo.new(
          id: model["id"],
          created_at: Time.parse(model["created_at"]),
          display_name: model["display_name"],
          provider: "anthropic",
          metadata: {
            type: model["type"]
          },
          context_window: determine_context_window(model["id"]),
          max_tokens: determine_max_tokens(model["id"]),
          supports_vision: supports_vision?(model["id"]),
          supports_functions: supports_functions?(model["id"]),
          supports_json_mode: supports_json_mode?(model["id"]),
          input_price_per_1k: get_input_price(model["id"]),
          output_price_per_1k: get_output_price(model["id"])
        )
      end
    end

    private

    def determine_context_window(model_id)
      case model_id
      when /claude-3-5-sonnet/, /claude-3-5-haiku/,
           /claude-3-opus/, /claude-3-sonnet/, /claude-3-haiku/
        200_000
      else
        100_000
      end
    end

    def determine_max_tokens(model_id)
      case model_id
      when /claude-3-5-sonnet/, /claude-3-5-haiku/
        8_192
      when /claude-3-opus/, /claude-3-sonnet/, /claude-3-haiku/
        4_096
      else
        4_096
      end
    end

    def get_input_price(model_id)
      case model_id
      when /claude-3-5-sonnet/
        0.003  # $3.00 per million tokens
      when /claude-3-5-haiku/
        0.0008 # $0.80 per million tokens
      when /claude-3-opus/
        0.015  # $15.00 per million tokens
      when /claude-3-sonnet/
        0.003  # $3.00 per million tokens
      when /claude-3-haiku/
        0.00025 # $0.25 per million tokens
      else
        0.003
      end
    end

    def get_output_price(model_id)
      case model_id
      when /claude-3-5-sonnet/
        0.015  # $15.00 per million tokens
      when /claude-3-5-haiku/
        0.004  # $4.00 per million tokens
      when /claude-3-opus/
        0.075  # $75.00 per million tokens
      when /claude-3-sonnet/
        0.015  # $15.00 per million tokens
      when /claude-3-haiku/
        0.00125 # $1.25 per million tokens
      else
        0.015
      end
    end

    def supports_vision?(model_id)
      case model_id
      when /claude-3-5-haiku/
        false
      else
        true
      end
    end

    def supports_functions?(model_id)
      model_id.include?("claude-3")
    end

    def supports_json_mode?(model_id)
      model_id.include?("claude-3")
    end
  end
end
