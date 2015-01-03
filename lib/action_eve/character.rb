module ActionEve
  
  class Character < Base

    def corporation
      Corporation.new({:id => corporation_id, :name => corporation_name}, @api, self)
    end
  
    def info
      character_info = @api.character_info(self.id)
      @options[:character_id] = self.id
      @options.merge!(character_info)
    end

    def implants
      implants = @api.character_implants(self.id)
    end

    def traits
      @api.traits(self.id)
    end

    def skills
      skills = []
      character_skills = @api.character_skills(self.id)
      character_skills.each do |skill|
        skills << Skill.new(skill, @api)
      end
      skills
    end

    def wallet_transactions
      @api.wallet_transactions(self.id)
    end

    def skill_queue
      @api.skill_queue(self.id)
    end
  
  end
  
end
