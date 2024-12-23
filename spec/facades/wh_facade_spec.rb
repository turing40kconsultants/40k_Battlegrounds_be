require 'rails_helper'

describe WhFacade do

  before :each do
    @faction1 = Faction.create!(name: "Necrons")
    @faction2 = Faction.create!(name: "Dark Angels")
  end

  context "#get_units_by_faction" do
    it "can create Necron units with hash data from GithubService", :vcr do

      response = WhFacade.new.get_units_by_faction("Necrons.cat", @faction1)
# binding.pry
      expect(response).to be_all Unit
      expect(response.count).to eq(59)
      expect(Weapon.all.count).to eq(119)
      expect(WeaponAbility.all.count).to eq(160)
    end

    it "can create Dark Angels units with hash data from GithubService", :vcr do
      response = WhFacade.new.get_units_by_faction("Imperium%20-%20Dark%20Angels.cat", @faction2)

      expect(response).to be_all Unit
      expect(response.count).to eq(19)
      expect(Weapon.all.count).to eq(67)
      expect(WeaponAbility.all.count).to eq(89)
    end
  end

  context "Formatting data for model creation" do
    it "can format units info", :vcr do
      response = WhFacade.new.get_units_data_by_faction("Necrons.cat")
      clean_data = WhFacade.new.clean_units_data(response, @faction1).first
      
      expect(clean_data).to have_key(:name)
      expect(clean_data[:name]).to be_a(String)
  
      expect(clean_data).to have_key(:movement)
      expect(clean_data[:movement]).to be_a(Integer)
  
      expect(clean_data).to have_key(:toughness)
      expect(clean_data[:toughness]).to be_a(Integer)
  
      expect(clean_data).to have_key(:sv)
      expect(clean_data[:sv]).to be_a(Integer)

      if clean_data[:invul_sv].nil?
        expect(clean_data[:invul_sv]).to be_nil
      else
        expect(clean_data[:invul_sv]).to be_a(Integer)
      end

      expect(clean_data).to have_key(:wounds)
      expect(clean_data[:wounds]).to be_a(Integer)

      expect(clean_data).to have_key(:leadership)
      expect(clean_data[:leadership]).to be_a(Integer)

      expect(clean_data).to have_key(:objective_control)
      expect(clean_data[:objective_control]).to be_a(Integer)

      expect(clean_data).to have_key(:weapons)
      expect(clean_data[:weapons]).to be_a(Array)
    end

    it "can format weapons info", :vcr do
      response = WhFacade.new.get_units_data_by_faction("Necrons.cat").first[:weapons]
      clean_data = WhFacade.new.clean_weapons_data(response).each do |clean_data|
      
      expect(clean_data).to have_key(:name)
      expect(clean_data[:name]).to be_a(String)
  
      expect(clean_data).to have_key(:attacks)
      expect(clean_data[:attacks]).to be_a(String)
  
      expect(clean_data).to have_key(:ws)
      expect(clean_data[:ws]).to be_a(Integer)
  
      expect(clean_data).to have_key(:strength)
      expect(clean_data[:strength]).to be_a(Integer)

      expect(clean_data).to have_key(:ap)
      expect(clean_data[:ap]).to be_a(Integer)

      expect(clean_data).to have_key(:damage)
      expect(clean_data[:damage]).to be_a(String)

      expect(clean_data).to have_key(:range)
      expect(clean_data[:range]).to be_a(Integer)
      end
    end

    it "can format weapon abilities info", :vcr do
      response = WhFacade.new.get_units_data_by_faction("Necrons.cat").first[:weapons].first[:abilities]
      clean_data = WhFacade.new.clean_abilities_data(response)

      if !clean_data.empty?
        expect(clean_data).to have_key(:name)
        expect(clean_data[:name]).to be_a(String)
  
        expect(clean_data).to have_key(:description)
        expect(clean_data[:description]).to be_a(String)
      end
    end

    it "can check of invul_sv by name" do 
      response1 = WhFacade.new.get_units_data_by_faction("Necrons.cat")
      clean_data = WhFacade.new.clean_units_data(response1, @faction1)

      response2 = WhFacade.new.get_units_data_by_faction("Imperium%20-%20Dark%20Angels.cat")
      clean_data2 = WhFacade.new.clean_units_data(response2, @faction1)

      expect(WhFacade.new.check_for_invul_sv(clean_data[0][:name])).to be(4)
      expect(WhFacade.new.check_for_invul_sv(clean_data.last[:name])).to be(4)

      expect(WhFacade.new.check_for_invul_sv(clean_data2[5][:name])).to be(3)
      expect(WhFacade.new.check_for_invul_sv(clean_data2.last[:name])).to be_nil

    end
  end
end
