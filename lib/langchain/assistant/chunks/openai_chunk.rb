module Langchain
  class Assistant
    module Chunks
      class OpenAIChunk < Base
        def start?
          raw_chunk.dig("delta", "role") == "assistant"
        end

        def end?
          not raw_chunk.dig("finish_reason").nil?
        end

        def tool?
          raw_chunk.dig("delta", "tool_calls")
        end

        def content
          raw_chunk.dig("delta", "content")
        end

        def function_names
          if self.tool?
            tool_calls = raw_chunk.dig("delta", "tool_calls")
            tool_calls&.map { |tool_call| [tool_call.dig("index"), tool_call.dig("function", "name")] }
          end
        end

        def function_arguments
          if self.tool?
            tool_calls = raw_chunk.dig("delta", "tool_calls")
            tool_calls&.map { |tool_call| [tool_call.dig("index"),tool_call.dig("function", "arguments")] }
          end
        end

        def finish_reason
          raw_chunk.dig("finish_reason")
        end
      end
    end
  end
end
