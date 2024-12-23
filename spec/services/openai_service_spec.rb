require 'rails_helper'

describe OpenaiService do
  describe '#generate_prompt' do
    let(:service) { OpenaiService.new }
    
    context 'when API call is successful' do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
            status: 200,
            body: {
              choices: [
                {
                  message: {
                    content: "Here's a strategy for your Necron army..."
                  }
                }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns generated content from OpenAI' do
        prompt = "Give me a strategy for my Necron army"
        response = service.generate_prompt(prompt)
        
        expect(response).to be_a(String)
        expect(response).to include("Here's a strategy for your Necron army")
      end
    end

    context 'when API call fails' do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
            status: 401,
            body: { error: "Invalid API key" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an error' do
        prompt = "Give me a strategy for my Necron army"

        expect { service.generate_prompt(prompt) }.to raise_error(Faraday::UnauthorizedError)
      end
    end
  end
end
