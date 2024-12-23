require 'openai'

class OpenaiService
  def initialize
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.openai[:key]) || ENV['OPENAI_API_KEY']
  end

  def generate_prompt(prompt)
    response = @client.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: prompt }],
        max_tokens: 1000,
        temperature: 0.7,
      }
    )

    if response.key?("error")
      raise OpenAI::Error, response.dig("error", "message")
    end

    response.dig("choices", 0, "message", "content")
  end
end