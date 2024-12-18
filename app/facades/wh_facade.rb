class WhFacade
  def initialize
    @invul_sv_four_units = [
      "Azrael",
      "Belial",
      "Sammael",
      "Ezekiel",
      "Asmodai",
      "Lazarus",
      "Deathwing Knights",
      "Deathwing Terminator Squad",
      "Deathwing Strikemaster [Legends]",
      "Orikan the Diviner",
      "Imotekh the Stormlord",
      "Anrakyr the Traveller [Legends]",
      "Illuminor Szeras",
      "Nemesor Zahndrekh [Legends]",
      "Trazyn the Infinite",
      "Skorpekh Lord",
      "Lokhust Lord",
      "Catacomb Command Barge",
      "Overlord",
      "Chronomancer",
      "Lychguard",
      "Triarch Stalker",
      "C'tan Shard of the Deceiver",
      "C'tan Shard of the Nightbringer",
      "C'tan Shard of the Void Dragon",
      "Transcendant C'tan",
      "Canoptek Wraiths",
      "Annihilation Barge",
      "Doomsday Ark",
      "Canoptek Doomstalker",
      "Ghost Ark",
      "Tesseract Vault",
      "The Silent King",
      "Canoptek Tomb Stalker [Legends]",
      "Canoptek Tomb Sentinel [Legends]",
      "Tesseract Ark [Legends]",
      "Overlord with Translocation Shroud"]

    @invul_sv_five_units = [
      "Nephilim Jetfighter",
      "Ravenwing Dark Talon",
      "Land Speeder Vengeance",
      "Ravenwing Darkshroud",
      "Ravenwing Black Knights",
      "Ravenwing Command Squad",
      "Ravenwing Talonmaster [Legends]",
      "Seraptek Heavy Construct",
      "Gauss Pylon [Legends]"]

    @invul_sv_three_units = ["Lion El'Jonson"]
  end
  
  def get_units_by_faction(path, faction)
    data = get_units_data_by_faction(path)
    clean_data = clean_units_data(data, faction)

    clean_data.each do |unit_data|
      unit = faction.units.create!(unit_data.except(:weapons))
      unit_data[:weapons].each do |weapon_data|
        weapon = unit.weapons.create!(weapon_data.except(:abilities))
        abilities = weapon_data[:abilities].map do |ability_data|
          weapon.weapon_abilities.create!(ability_data)
        end
      end
    end
    Unit.all
  end

  def clean_units_data(units_data, faction)
    units_data.map do |unit|
      {
        name: unit[:name],
        movement: unit[:stats][0].delete('\"').to_i, 
        toughness: unit[:stats][1].to_i, 
        sv: unit[:stats][2].delete('+').to_i,
        invul_sv: check_for_invul_sv(unit[:name]),
        wounds: unit[:stats][3].to_i, 
        leadership: unit[:stats][4].delete('+').to_i, 
        objective_control: unit[:stats][5].to_i, 
        faction: faction,
        weapons: clean_weapons_data(unit[:weapons])
      }
    end
  end

  def clean_weapons_data(weapons_data)
    weapons_data.map do |weapon|
      if weapon[:typeName] != "Abilities"
        {
          name: weapon[:name],
          attacks: weapon[:characteristics][1],
          ws: weapon[:characteristics][2].delete('+').to_i,
          strength: weapon[:characteristics][3].to_i,
          ap: weapon[:characteristics][4].delete('-').to_i,
          damage: weapon[:characteristics][5],
          range: if weapon[:characteristics][0] == "Melee"
                    0
                  else
                    weapon[:characteristics][0]
                  end,
          abilities: clean_abilities_data(weapon[:characteristics][6])
        }
      end
    end.compact
  end

  def clean_abilities_data(abilities_data)
    if abilities_data.nil?
      {name: "-", description: "refer to game rules"}
    else
      abilities_to_array = abilities_data.split(',').map { |element| element.strip }
      abilities_to_array.map do |ability|
        {
          name: abilities_data,
          description: 'Refer to game rules'
        }
      end
    end
  end

  def check_for_invul_sv(name)
    if @invul_sv_five_units.include?(name)
      5
    elsif @invul_sv_four_units.include?(name)
      4
    elsif @invul_sv_three_units.include?(name)
      3
    end
  end

  def get_units_data_by_faction(path)
    search = GithubService.get_units_by_faction(path)
    units = search[:catalogue][:sharedSelectionEntries][:selectionEntry].flat_map do |unit|
      collection = []

      if unit[:type] == "unit"

        name = unit[:name]

        stats = 
          if unit[:profiles][:profile].is_a?(Hash)
            unit[:profiles][:profile][:characteristics][:characteristic]
          else
            stat_data =
            unit[:profiles][:profile].find do |entry|
              entry[:typeName] == "Unit"
            end
            if stat_data
              stat_data[:characteristics][:characteristic]
            else
              if unit[:selectionEntryGroups]
                if unit[:selectionEntryGroups][:selectionEntryGroup].is_a?(Hash)
                  unit[:selectionEntryGroups][:selectionEntryGroup][:selectionEntries][:selectionEntry][0][:profiles][:profile][:characteristics][:characteristic]
                else
                  unit[:selectionEntryGroups][:selectionEntryGroup][0][:selectionEntries][:selectionEntry][0][:profiles][:profile][:characteristics][:characteristic]
                end
              else
                unit[:selectionEntries][:selectionEntry][0][:profiles][:profile][:characteristics][:characteristic]
              end
            end
          end

        weapon_profiles = []

        if unit[:selectionEntries]
          if unit[:selectionEntries][:selectionEntry].is_a?(Array)
            unit[:selectionEntries][:selectionEntry].each do |entry|
              entry[:selectionEntries][:selectionEntry].each do |entry|
                weapon_profiles << entry[:profiles][:profile]
                
              end
            end
          elsif unit[:selectionEntries][:selectionEntry].is_a?(Hash) && unit[:selectionEntries][:selectionEntry][:selectionEntries]
            if unit[:selectionEntries][:selectionEntry][:selectionEntries][:selectionEntry].is_a?(Hash)
              weapon_profiles << unit[:selectionEntries][:selectionEntry][:selectionEntries][:selectionEntry][:profiles][:profile]
            elsif unit[:selectionEntries][:selectionEntry][:selectionEntries][:selectionEntry].is_a?(Array)
              unit[:selectionEntries][:selectionEntry][:selectionEntries][:selectionEntry].each do |entry|
                if entry[:profiles]
                weapon_profiles << entry[:profiles][:profile] if entry[:profiles][:profile].is_a?(Hash)
                  if entry[:profiles][:profile].is_a?(Array)
                    entry[:profiles][:profile].each do |weapon|
                      weapon_profiles << weapon
                    end
                  end
                elsif entry[:selectionEntries]
                  weapon_profiles << entry[:selectionEntries][:selectionEntry][:profiles][:profile]
                end
              end
            end
          end
        end

        if unit[:selectionEntryGroups]
          if unit[:selectionEntryGroups][:selectionEntryGroup].is_a?(Array)
            unit[:selectionEntryGroups][:selectionEntryGroup][1][:selectionEntries][:selectionEntry].each do |entry|
              weapon_profiles << entry[:profiles][:profile]
            end
          elsif unit[:selectionEntryGroups][:selectionEntryGroup].is_a?(Hash)
            profile = unit[:selectionEntryGroups][:selectionEntryGroup][:selectionEntries][:selectionEntry]
            if profile.is_a?(Array)
              profile.each do |entry|
                if entry[:selectionEntries]
                  if entry[:selectionEntries][:selectionEntry].is_a?(Hash)
                    weapon_profiles << entry[:selectionEntries][:selectionEntry][:profiles][:profile]
                  else
                    entry[:selectionEntries][:selectionEntry].each do |nested_entry|
                      weapon_profiles << nested_entry[:profiles][:profile]
                    end
                  end
                end
              end
            elsif profile[:selectionEntryGroups]
              if profile[:selectionEntryGroups][:selectionEntryGroup].is_a?(Array)
                profile[:selectionEntryGroups][:selectionEntryGroup].each do |group|
                  group[:selectionEntries][:selectionEntry].each do |nested_entry|
                    weapon_profiles << nested_entry[:profiles][:profile] if nested_entry[:profiles][:profile].is_a?(Hash)
                  end
                end
              else
                profile[:selectionEntryGroups][:selectionEntryGroup][:selectionEntries][:selectionEntry].each do |group|
                  weapon_profiles << group[:profiles][:profile] if group[:profiles][:profile].is_a?(Hash)
                  if group[:profiles][:profile].is_a?(Array)
                    group[:profiles][:profile].each do |weapon|
                      weapon_profiles << weapon
                    end
                  end
                end
              end
            elsif profile[:selectionEntries][:selectionEntry].is_a?(Hash)
              weapon_profiles << profile[:selectionEntries][:selectionEntry][:profiles][:profile]
            elsif profile[:selectionEntries][:selectionEntry].is_a?(Array)
              profile[:selectionEntries][:selectionEntry].each do |entry|
                weapon_profiles << entry[:profiles][:profile] if entry[:profiles][:profile].is_a?(Hash)
                if entry[:profiles][:profile].is_a?(Array)
                  entry[:profiles][:profile].each do |weapon|
                    weapon_profiles << weapon
                  end
                end
              end
            elsif profile[:selectionEntryGroups][:selectionEntryGroup][:selectionEntries][:selectionEntry].each do |entry|
              weapon_profiles << entry[:profiles][:profile] if entry[:profiles][:profile].is_a?(Hash)
                if entry[:profiles][:profile].is_a?(Array)
                  entry[:profiles][:profile].each do |weapon|
                    weapon_profiles << weapon
                  end
                end
              end
            end
          end
        end

        weapons = weapon_profiles.flatten.map do |profile| 
          { 
            name: profile[:name],
            typeName: profile[:typeName],
            characteristics: profile[:characteristics][:characteristic]
          }
        end.uniq

        collection << {
          :name => name,
          :stats => stats,
          :weapons => weapons
        }
        # if weapons == nil || weapons.empty?
        #   binding.pry
        # end

        # if stats == nil
        #   binding.pry
        # end
      end
# ================================================================
      if unit[:type] == "model"

        name = unit[:name]

        stats = unit[:profiles][:profile].flat_map do |entry|
          entry[:characteristics][:characteristic] if entry[:typeName] == "Unit"
        end.compact

        weapon_profiles = []
        if unit[:selectionEntries].is_a?(Hash)
          if unit[:selectionEntries][:selectionEntry].is_a?(Hash)
            if unit[:selectionEntries][:selectionEntry][:profiles][:profile].is_a?(Hash)
              weapon_profiles << unit[:selectionEntries][:selectionEntry][:profiles][:profile]
            elsif unit[:selectionEntries][:selectionEntry][:profiles][:profile].is_a?(Array)
              unit[:selectionEntries][:selectionEntry][:profiles][:profile].each do |profile|
                weapon_profiles << profile
              end
            end
          elsif unit[:selectionEntries][:selectionEntry].is_a?(Array)
            unit[:selectionEntries][:selectionEntry].each do |entry|
              if entry[:profiles][:profile].is_a?(Hash)
                weapon_profiles << entry[:profiles][:profile]
              elsif entry[:profiles][:profile].is_a?(Array)
                entry[:profiles][:profile].each do |profile|
                  weapon_profiles << profile
                end
              end
            end
          end
        elsif unit[:selectionEntryGroups]
          if unit[:selectionEntryGroups][:selectionEntryGroup].is_a?(Array)
            unit[:selectionEntryGroups][:selectionEntryGroup].each do |group|
              if group[:selectionEntries][:selectionEntry].is_a?(Array)
                group[:selectionEntries][:selectionEntry].each do |entry|
                  if entry[:profiles][:profile].is_a?(Hash)
                    weapon_profiles << entry[:profiles][:profile]
                  elsif entry[:profiles][:profile].is_a?(Array)
                    entry[:profiles][:profile].each do |profile|
                      weapon_profiles << profile
                    end
                  end
                end
              elsif group[:selectionEntries][:selectionEntry].is_a?(Hash)
                if group[:selectionEntries][:selectionEntry][:profiles][:profile].is_a?(Hash)
                  weapon_profiles << group[:selectionEntries][:selectionEntry][:profiles][:profile]
                elsif group[:selectionEntries][:selectionEntry][:profiles][:profile].is_a?(Array)
                  group[:selectionEntries][:selectionEntry][:profiles][:profile].each do |profile|
                    weapon_profiles << profile
                  end
                end
              end
            end
          elsif unit[:selectionEntryGroups][:selectionEntryGroup].is_a?(Hash)
            if unit[:selectionEntryGroups][:selectionEntryGroup][:selectionEntries][:selectionEntry].is_a?(Array)
              unit[:selectionEntryGroups][:selectionEntryGroup][:selectionEntries][:selectionEntry].each do |entry|
                if entry[:profiles]
                  if entry[:profiles][:profile].is_a?(Hash)
                    weapon_profiles << entry[:profiles][:profile]
                  elsif entry[:profiles][:profile].is_a?(Array)
                    entry[:profiles][:profile].each do |profile|
                      weapon_profiles << profile
                    end
                  end
                end
              end
            elsif unit[:selectionEntryGroups][:selectionEntryGroup][:selectionEntries][:selectionEntry].is_a?(Hash)
              if unit[:selectionEntryGroups][:selectionEntryGroup][:selectionEntries][:selectionEntry][:selectionEntries][:selectionEntry].is_a?(Array)
                unit[:selectionEntryGroups][:selectionEntryGroup][:selectionEntries][:selectionEntry][:selectionEntries][:selectionEntry].each do |entry|
                  if entry[:profiles]
                    if entry[:profiles][:profile].is_a?(Hash)
                      weapon_profiles << entry[:profiles][:profile]
                    elsif entry[:profiles][:profile].is_a?(Array)
                      entry[:profiles][:profile].each do |profile|
                        weapon_profiles << profile
                      end
                    end
                  end
                end
              end
            end
          end
        end

        weapons = weapon_profiles.map do |profile| 
          { 
            name: profile[:name],
            typeName: profile[:typeName],
            characteristics: profile[:characteristics][:characteristic]
          }
        end

        collection << {
          :name => name,
          :stats => stats,
          :weapons => weapons
        }
      end
      collection
    end
  end
end

def reformat_weapon_data(weapon_list)
    weapon_list.map do |weapon|
      weapon[:characteristics]
    end
end