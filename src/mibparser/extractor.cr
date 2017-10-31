


module CrSNMP::MIBParser

  struct ExtractedImport
    property symbol_names : Array(String)
    property mib : String

    def initialize(@mib, @symbol_names)
    end
  end

  enum MIBSymbolType
    Unknown
    TypeDefinition
    ObjectType
    ObjectIdentifier
  end

  abstract class MIBSymbol
    property identifier : String

    def initialize(@identifier)
    end

    def type
      MIBSymbolType::Unknown
    end
  end

  class TypeDefinitionSymbol < MIBSymbol
    property application : Int8 | Nil
    property implicit : Bool
    property definition : String

    def initialize(@identifier, @definition, @application = 0, @implicit = false)
      super @identifier
    end

    def type
      MIBSymbolType::TypeDefinition
    end

  end

  struct ExportedOIDNumber
    property number : Int32

    def initialize(@number)
    end
  end

  struct ExportedOIDSymbol
    property symbol_name : String

    def initialize(@symbol_name)
    end
  end

  struct ExportedOIDForwardSymbol
    property symbol_name : String
    property number : Int32

    def initialize(@symbol_name, @number)
    end
  end

  struct ExportedOID
    property fragments : Array(ExportedOIDNumber | ExportedOIDSymbol | ExportedOIDForwardSymbol)

    def initialize(@fragments)
    end
  end

  class ObjectTypeSymbol < MIBSymbol
    property syntax : String
    property access : String
    property status : String
    property description : String
    property oid : ExportedOID
    property index : String | Nil

    def initialize(@identifier, @syntax, @access, @status, @description, @oid, @index = "")
      super @identifier
    end

    def type
      MIBSymbolType::ObjectType
    end

  end

  class ObjectIdentifierSymbol < MIBSymbol
    property oid : ExportedOID

    def initialize(@identifier, @oid)
      super @identifier
    end

    def type
      MIBSymbolType::ObjectIdentifier
    end

  end

  class ExtractedMIB
    property symbols : Hash(String, MIBSymbol)
    property exports : Array(String)
    property imports : Array(ExtractedImport)
    property name : String

    def initialize(@name, @symbols, @imports, @exports = [] of String)
    end

  end

  class Extractor

    @@regex_mib = /(?<filename>[a-zA-Z0-9-_]+)\s*DEFINITIONS\s*::=\s*BEGIN\s*(IMPORTS\s*(?<imports>.+?)\s*;)?\s*(EXPORTS\s*(?<exports>.+?)\s*;)?\s*(?<body>.*)\s*END/m
    @@regex_comment = /--.*$/
    @@regex_macro = /OBJECT-TYPE\sMACRO\s::=\s+BEGIN.+?END/m
    @@regex_oid = /(?<oid>\{\s*([a-zA-Z0-9-_](\([0-9]+\))?+\s?)+\s*\})/
    @@regex_object_type = /(?<identifier>[a-zA-Z0-9]+)\s+OBJECT-TYPE\s+SYNTAX\s+(?<syntax>.+?)\s+ACCESS\s+(?<access>read-only|read-write|write-only|not-accessible)\s+STATUS\s+(?<status>mandatory|optional|obsolete)\s+DESCRIPTION\s+"(?<description>.+?)"\s+(INDEX\s+\{\s*(?<index>[\sa-zA-Z0-9,]+?)\s*\})?\s+::=\s+(?<oid>\{\s*([a-zA-Z0-9-_](\([0-9]+\))?+\s?)+\s*\})/m
    @@regex_object_id = /(?<identifier>[a-zA-Z0-9-_]+?)\s+OBJECT\sIDENTIFIER\s+::=\s+(?<oid>\{\s*([a-zA-Z0-9-_](\([0-9]+\))?+\s?)+\s*\})/m
    @@regex_type = /(?<identifier>[a-zA-Z0-9]+)\s+::=\s+(\[APPLICATION (?<application>[0-9]+)\]\s+)?(?<implicit>IMPLICIT\s+)?(?<rightHand>((OCTET STRING|INTEGER|NULL|OBJECT IDENTIFIER)(\s+\([a-zA-Z0-9\.\s\(\)]+\))?)|SEQUENCE\s+\{.+?\}|CHOICE\s+\{.+?\})/m

    def extract(mib : String) : ExtractedMIB
      # komentarze usuwamy
      mib = mib.gsub @@regex_comment, ""

      # główna struktura pliku
      structure = @@regex_mib.match(mib)
      if structure.nil?
        raise "invalid MIB file"
      end

      name = structure["filename"]

      # makra usuwamy
      body = structure["body"].gsub @@regex_macro, ""

      # wszystkie symbole
      symbols = extract_symbols body

      ExtractedMIB.new name, symbols, [] of ExtractedImport
    end

    def extract_symbols(body : String) : Hash(String, MIBSymbol)
      symbols = {} of String => MIBSymbol

      # identifier
      body.scan(@@regex_object_id) do |id_match|
        id = id_match["identifier"]
        oid = id_match["oid"]
        symbols[id] = ObjectIdentifierSymbol.new(id, parse_oid(oid))
      end
      body = body.gsub @@regex_object_id, ""

      # object-type
      body.scan(@@regex_object_type) do |id_match|
        puts "?"
        id = id_match["identifier"]
        oid = id_match["oid"]
        syntax = id_match["syntax"]
        access = id_match["access"]
        status = id_match["status"]
        description = id_match["description"]
        index = id_match["index"]?

        symbols[id] = ObjectTypeSymbol.new(id, syntax, access, status, description, parse_oid(oid), index)
      end
      body = body.gsub @@regex_object_type, ""

      # types
      body.scan(@@regex_type) do |id_match|
        id = id_match["identifier"]
        application = id_match["application"]?
        implicit = id_match["implicit"]?
        definition = id_match["rightHand"]

        symbols[id] = TypeDefinitionSymbol.new(id, definition, application.nil? ? nil : application.to_i8, !implicit.nil?)
      end

      symbols
    end

    def parse_oid(oid : String) : ExportedOID
      # klamry, spacje i podzielić
      oid = oid.strip "{}\t\r\n "
      exploded = oid.split ' '

      fragments = exploded.map do |frag|
        if /^[0-9]+$/.match(frag)
          ExportedOIDNumber.new(frag.to_i32)
        elsif /^[a-zA-Z0-9-_]+$/.match(frag)
          ExportedOIDSymbol.new(frag)
        else
          forward = /^([a-zA-Z0-9-_]+)\(([0-9]+)\)$/.match(frag)

          if forward.nil?
            raise "could not parse oid"
          end

          ExportedOIDForwardSymbol.new(forward[0], forward[1].to_i32)
        end
      end

      ExportedOID.new(fragments)
    end

  end

end
