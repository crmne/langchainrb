module Langchain
  class Assistant
    module Chunks
      class Base
        attr_reader :raw_chunk, :index

        def initialize(raw_chunk)
          @raw_chunk = raw_chunk
          @index = raw_chunk.dig("index")
        end

        def start?
          raise NotImplementedError
        end

        def end?
          raise NotImplementedError
        end

        def tool?
          raise NotImplementedError
        end

        def content
          raise NotImplementedError
        end

        def function_names
          raise NotImplementedError
        end

        def function_arguments
          raise NotImplementedError
        end

        def finish_reason
          raise NotImplementedError
        end
      end
    end
  end
end
