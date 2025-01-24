module Langchain
  class Assistant
    module Chunks
      class AnthropicChunk < Base
        def start?
          raw_chunk.dig("type") == "message_start"
        end

        def end?
          raw_chunk.dig("type") == "message_stop"
        end

        def tool?
          raw_chunk.dig("content_block", "type") == "tool_use" or raw_chunk.dig("delta", "type") == "input_json_delta"
        end

        def content
          raw_chunk.dig("delta", "text")
        end

        def function_names
          if tool?
            [raw_chunk.dig("content_block", "name")]
          end
        end

        def function_arguments
          if tool?
            [raw_chunk.dig("delta", "partial_json")]
          end
        end

        def finish_reason
          raw_chunk.dig("delta", "stop_reason")
        end
      end
    end
  end
end
