module ActionEve

  class Base
    
    def initialize(options, api=nil)
      @api ||= api
      @api ||= Comms::API.new(options)
      @options = options
    end
    
    def id
      @options[:character_id] || @options[:id]
    end
    
    def type
      @options[:type]
    end

    def fields
      ap @options
    end
    
    def method_missing(method, *args)
      if @options.has_key?(method.to_sym)
        return(@options[method.to_sym])
      end
      raise(Exceptions::MethodException,"That method is missing, check under the cushion")
    end

    def parse_args!(args)
      args.last.is_a?(Hash) ? args.pop : {}
    end

  end

end
