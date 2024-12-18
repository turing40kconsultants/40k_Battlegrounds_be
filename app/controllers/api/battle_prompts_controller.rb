class BattlePromptsController < ApplicationController
  def create
    client = OpenAIClient.new
    prompt = "Generate a Warhammer 40k battle cry for the Ultramarines."
    @response = client.generate_prompt(prompt)

    render json: { battle_cry: @response }
  end
end