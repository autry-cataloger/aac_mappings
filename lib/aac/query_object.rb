module AAC
  class QueryObject
    self::DEFAULT_PREFIXES = {
        owl: "http://www.w3.org/2002/07/owl#",
        rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        rdfs: "http://www.w3.org/2000/01/rdf-schema#",
        crm: "http://erlangen-crm.org/current/",
        skos: "http://www.w3.org/2004/02/skos/core#",
        xsd: "http://www.w3.org/2001/XMLSchema#"
    }
    def self.prefix_list 
      DEFAULT_PREFIXES.collect {|key,value| "PREFIX #{key}: <#{value}>"}.join("\n")
    end

    attr_accessor :select, :construct, :where, :prefixes
    attr_writer :values

    def initialize(obj = {})
      @obj = obj
      self.select    = obj.fetch("select"    , nil)
      self.construct = obj.fetch("construct" , nil)
      self.where     = obj.fetch("where"     , nil)
      self.values    = obj.fetch("values"    , nil)
    end

    def values(args)

      parameters = @values.split(" ").collect do |parameter|
        key_value = parameter.gsub("?","")
        args.has_key?(key_value) ? "<#{args[key_value]}>" : nil
      end.compact.join(" ")

      "VALUES (#{@values}) {(#{parameters})}" 
    end
    def replace_values(query, args) 

      @values.split(" ").each do |parameter|
        key_value = parameter.gsub("?","")
      query.gsub!(parameter, "<#{args[key_value]}>") if args.has_key?(key_value)
      end
      query
    end

    def construct_query(args)
      query = <<~eos
        #{QueryObject.prefix_list}
        #{@prefixes}

        CONSTRUCT {
          #{@construct}
        }
        WHERE {
          {
          #{@where}
          }
          UNION
          {
            #{@construct.gsub("_:","_:construct_")}
          }          
        }
      eos
      replace_values(query, args)
    end
    def select_query(args)
      query = <<~eos
        #{QueryObject::prefix_list}
        #{@prefixes}

        SELECT #{@select}
        WHERE {
          {
          #{@where}
          }
          UNION
          {
            #{@construct.gsub("_:","_:construct_")}
          }      
        }
      eos
      replace_values(query, args)
    end
  end
end