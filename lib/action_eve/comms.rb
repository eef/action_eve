require 'date'
require 'net/http'
require 'digest/sha1'
require 'uri'

module ActionEve
  
  module Comms
    
    class API

      IMPLANT_TYPES = {
        "memoryBonus" => "memory",
        "willpowerBonus" => "willpowerBonus",
        "perceptionBonus" => "perception",
        "intelligenceBonus" => "intelligence",
        "charismaBonus" => "charisma"
      }
      
      def initialize(*args)
        @options = parse_args!(args)
        @comms = Request.new(@options)
      end

      def characters
        result = {}
        doc = @comms.call('account/Characters.xml.aspx')
        doc.css('rowset[name="characters"] > row').each do |row|
          character = {
            :id => row['characterID'].to_i,
            :character_id => row['characterID'].to_i,
            :character_name => row['name'],
            :corporation_id => row['corporationID'].to_i,
            :corporation_name => row['corporationName']
          }
          result[character[:id]] = character
        end
        result
      end

      def api_key_info
        result = {}
        doc = @comms.call('account/APIKeyInfo.xml.aspx')
        puts doc
        doc.css('key').each do |row|
          result = {
            :bitmask => row['accessMask'],
            :expires => "#{Time.parse(row['expires']) unless row['expires'].eql?("")}",
            :key_type => row['type']
          }
        end
        result
      end
      
      def character_info(character_id)
        result = {}
        doc = @comms.call('eve/CharacterInfo.xml.aspx', :characterID => character_id)
        rows = doc.css('result').first.children
        rows.each {|row| result[row.name.underscore.to_sym] = row.text}
        unless @options[:id].nil? and @options[:vcode].nil?
          result = more_info(result, character_id)
          result[:api_id] = @options[:id]
          result[:api_vcode] = @options[:vcode]
        end
        result.delete(:rowset)
        result.delete(:text)
        result
      end

      def character_implants(character_id)
        result = []
        doc = @comms.call('char/CharacterSheet.xml.aspx', :characterID => character_id)
        rows = doc.css('attributeEnhancers').first.children
        rows.each do |row|
          name = row.name
          if !IMPLANT_TYPES[name].nil?
            result << build_implant(row) if row.child
          end
        end
        result
      end

      def skill_queue(character_id)
        queue = {}
        queue[:ids] = {}
        queue[:group_ids] = {}
        items = []
        total_length = 0
        position = 0
        doc = @comms.call('char/SkillQueue.xml.aspx', :characterID => character_id)
        rows = doc.css("row")
        @from_time = Time.now.to_i
        rows.each do |row|
          unless row["endTime"].blank?
            time_left = DateTime.parse(row["endTime"]).to_i - @from_time
            total_length += time_left
            @from_time = DateTime.parse(row["endTime"]).to_i
            if time_left > 0
              t = {
                :position =>  position.to_s,
                :skill =>  row["typeID"],
                :level => row["level"],
                :start_sp => row["startSP"],
                :end_sp => row["endSP"],
                :start_time => DateTime.parse(row["startTime"]),
                :end_time => DateTime.parse(row["endTime"]),
                :time_left => time_left,
                :trained_for => Time.now.to_i - DateTime.parse(row["startTime"]).to_i
              }
              if position.eql?(0)
                queue[:currently_training] = row["typeID"]
              else
                if queue[:ids].has_key?(row["typeID"])
                  queue[:ids][row["typeID"]] += 1
                else
                  queue[:ids][row["typeID"]] = 1
                end
              end
              items[position] = t
              position += 1
            end
          end
        end
        queue[:items] = items
        queue[:total_time] = total_length
        queue
      end

      def total_queue_length(queue)
        
      end

      def traits(character_id)
        ret = {}
        doc = @comms.call('char/CharacterSheet.xml.aspx', :characterID => character_id)
        rows = doc.css('attributes').first.children
        rows.each do |row|
          ret[row.name.to_sym] = row.text.to_i unless row.name.eql?("text")
        end
        ret
      end

      def more_info(result, character_id)
        doc = @comms.call('char/CharacterSheet.xml.aspx', :characterID => character_id)
        result[:dob] = doc.css("DoB").text
        result[:clone_name] = doc.css("cloneName").text
        result[:clone_skillpoints] = doc.css("cloneSkillPoints").text
        result[:ancestry] = doc.css("ancestry").text
        result[:gender] = doc.css("gender").text
        result
      end
      
      def is_director(character_id)
        doc = @comms.call("char/CharacterSheet.xml.aspx", :characterID => character_id)
        if doc.css('row[roleName="roleDirector"]').length > 0
          true
        else
          false
        end
      end
      
      def character_skills(character_id)
        character_skills = []
        doc = @comms.call("char/CharacterSheet.xml.aspx", :characterID => character_id)
        rows = doc.css('rowset[name="skills"] > row')
        rows.each do |row|
          skill = {
            :type_id => row["typeID"],
            :skill_points => row["skillpoints"],
            :level => row["level"]
          }
          character_skills << skill
        end
        character_skills
      end

      def wallet_transactions(character_id)
        transactions = []
        doc = @comms.call('char/WalletTransactions.xml.aspx', :characterID => character_id)
        rows = doc.css('rowset[name="transactions"] > row')
        rows.each do |row|
          transaction = {
            :transaction_date_time => row['transactionDateTime'],
            :transaction_id => row['transactionID'],
            :quantity => row['quantity'],
            :market_item_name => row['typeName'],
            :market_item_id => row['typeID'],
            :price => row['price'],
            :client_id => row['clientID'],
            :client_name => row['clientName'],
            :station_id => row['stationID'],
            :station_name => row['stationName'],
            :transaction_type => row['transactionType'],
            :transaction_for => row['transactionFor'],
            :journal_transaction_id => row['journalTransactionID']
          }
          transactions << transaction
        end
        transactions
      end

      def character_sheet(character_id)

      end
      
      def corporation_info(corporation_id, character_id=nil)
        result = {}
        doc = @comms.call("corp/CorporationSheet.xml.aspx", :characterID => character_id, :corporation_id => corporation_id)
        rows = doc.css('result').first.children
        rows.each {|row| result[row.name.underscore.to_sym] = row.text unless row.name.eql?("logo")}
        result
      end
      
      def member_tracking(character_id)
        result = []
        doc = @comms.call("corp/MemberTracking.xml.aspx", :characterID => character_id)
        rows = doc.css('rowset > row')
        rows.each do |row|
          member = {}
          row.attributes.each do |key, value|
            member[key.underscore.to_sym] = value.value
          end
          result << member
        end
        result
      end

      def parse_args!(args)
        args.last.is_a?(Hash) ? args.pop : {}
      end

      private
        def build_implant(row)
          ret = {}
          children = row.children
          ret[:implant_type] = row.name.gsub("Bonus", "")
          ret[:value] = children.css("augmentatorValue").text
          ret[:name] = children.css("augmentatorName").text
          ret
        end
    end
    
    class Request
      
      def initialize(*args)
        options = parse_args!(args)
        @cache = Cache.new
        @initial_params = {}
        @initial_params[:keyID] = options[:id] or raise Exceptions::OptionsException, "Key ID is missing"
        @initial_params[:vcode] = options[:vcode] or raise Exceptions::OptionsException, "Verification Code is missing"
      end
    
      def call(uri, *args)
        params = parse_args!(args).merge(@initial_params)
        data = @cache.doc(params, uri)
        puts data[:error]
        unless data[:error].length.eql?(0)
          case data[:error].first['code'][0,1]
            when '1'
              raise Exceptions::InputException, data[:error].text
            when '2'
              raise Exceptions::CredentialsException, data[:error].text
            else
              raise Exceptions::APIException, data[:error].text
          end
        end
        data[:xml]
      end

      def parse_args!(args)
        args.last.is_a?(Hash) ? args.pop : {}
      end

    end

  end
  
end
