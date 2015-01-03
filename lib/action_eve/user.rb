module ActionEve
  
  class User < Base
    
    def initialize(*args)
      super(parse_args!(args))
      raise(Exceptions::InputException, "Key ID is missing") unless @options[:id]
      raise(Exceptions::InputException, "Verification Code is missing") unless @options[:vcode]
    end
    
    def characters
      characters = []
      @api.characters.each do |character_id, character|
        characters << Character.new(character, @api)
      end
      characters
    end

    def api_key_info
      @api.api_key_info
    end

    def find_character(id)
      ret = nil
      self.characters.each do |character|
        ret = character if character.id.eql?(id)
      end
      ret
    end

    
  end
  
end
