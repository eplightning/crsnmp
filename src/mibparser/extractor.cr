require "./extractor/*"

module CrSNMP::MIBParser

  REGEX_MIB = /(?<filename>[a-zA-Z0-9-_]+)\s*DEFINITIONS\s*::=\s*BEGIN\s*(IMPORTS\s*(?<imports>.+?)\s*;)?\s*(EXPORTS\s*(?<exports>.+?)\s*;)?\s*(?<body>.*)\s*END/m
  REGEX_COMMENT = /--[^\n]*$/m
  REGEX_MACRO = /OBJECT-TYPE\sMACRO\s::=\s+BEGIN.+?END/m
  REGEX_OID = /(?<oid>\{\s*([a-zA-Z0-9-_](\([0-9]+\))?+\s?)+\s*\})/
  REGEX_OBJECT_TYPE = /(?<identifier>[a-zA-Z0-9]+)\s+OBJECT-TYPE\s+SYNTAX\s+(?<syntax>.+?)\s+ACCESS\s+(?<access>read-only|read-write|write-only|not-accessible)\s+STATUS\s+(?<status>mandatory|optional|obsolete)\s+DESCRIPTION\s+"(?<description>.+?)"\s+(INDEX\s+\{\s*(?<index>[\sa-zA-Z0-9,]+?)\s*\})?\s+::=\s+(?<oid>\{\s*([a-zA-Z0-9-_](\([0-9]+\))?+\s?)+\s*\})/m
  REGEX_OBJECT_ID = /(?<identifier>[a-zA-Z0-9-_]+?)\s+OBJECT\sIDENTIFIER\s+::=\s+(?<oid>\{\s*([a-zA-Z0-9-_](\([0-9]+\))?+\s?)+\s*\})/m
  REGEX_TYPE = /(?<identifier>[a-zA-Z0-9]+)\s+::=\s+(?<rightHand>(\[APPLICATION ([0-9]+)\]\s+)?(IMPLICIT\s+)?(((OCTET STRING|INTEGER|NULL|OBJECT IDENTIFIER)(\s+\([a-zA-Z0-9\.\s\(\)]+\))?)|SEQUENCE\s+\{.+?\}|CHOICE\s+\{.+?\}))/m
  REGEX_IMPORT_LINE = /(?<identifiers>[a-zA-Z0-9,\s-_]+?)\sFROM\s+(?<filename>[a-zA-Z0-9-_]+)/m

  class ExtractedMIB
    property symbols : Hash(String, MIBSymbol)
    property exports : Array(String)
    property imports : Array(ExtractedImport)
    property name : String

    def initialize(@name, @symbols, @imports, @exports = [] of String)
    end

  end

  class Extractor


    def extract(mib : String) : ExtractedMIB
      # komentarze usuwamy
      mib = mib.gsub REGEX_COMMENT, ""

      # główna struktura pliku
      structure = REGEX_MIB.match(mib)
      if structure.nil?
        raise "invalid MIB file"
      end

      # makra usuwamy
      body = structure["body"].gsub REGEX_MACRO, ""

      name = structure["filename"]
      imports = extract_imports structure["imports"]?
      exports = extract_identifiers structure["exports"]?
      symbols = extract_symbols body

      ExtractedMIB.new name, symbols, imports, exports
    end

    private def extract_imports(imports : String | Nil) : Array(ExtractedImport)
      out = [] of ExtractedImport

      if !imports.nil?
        imports.scan(REGEX_IMPORT_LINE) do |line|
          out << ExtractedImport.new line["filename"], extract_identifiers(line["identifiers"])
        end
      end

      out
    end

    private def extract_identifiers(identifiers : String | Nil) : Array(String)
      if identifiers.nil?
        [] of String
      else
        identifiers.split(",").map &.strip
      end
    end

    private def extract_symbols(body : String) : Hash(String, MIBSymbol)
      symbols = {} of String => MIBSymbol

      # identifier
      body.scan(REGEX_OBJECT_ID) do |id_match|
        id = id_match["identifier"]
        oid = id_match["oid"]
        symbols[id] = ObjectIdentifierSymbol.new(id, parse_oid(oid))
      end
      body = body.gsub REGEX_OBJECT_ID, ""

      # object-type
      body.scan(REGEX_OBJECT_TYPE) do |id_match|
        id = id_match["identifier"]
        oid = id_match["oid"]
        syntax = id_match["syntax"]
        access = id_match["access"]
        status = id_match["status"]
        description = id_match["description"]
        index = id_match["index"]?

        symbols[id] = ObjectTypeSymbol.new(id, parse_type(syntax), access, status, description, parse_oid(oid), index)
      end
      body = body.gsub REGEX_OBJECT_TYPE, ""

      # types
      body.scan(REGEX_TYPE) do |id_match|
        id = id_match["identifier"]
        definition = id_match["rightHand"]

        symbols[id] = TypeDefinitionSymbol.new(id, parse_type(definition))
      end

      symbols
    end

    private def parse_type(definition : String) : ExtractedType
      UnknownExtractedType.new definition
    end

    private def parse_oid(oid : String) : ExtractedOID
      # klamry, spacje i podzielić
      oid = oid.strip "{}\t\r\n "
      exploded = oid.split ' '

      fragments = exploded.map do |frag|
        if /^[0-9]+$/.match(frag)
          ExtractedOIDNumber.new(frag.to_i32)
        elsif /^[a-zA-Z0-9-_]+$/.match(frag)
          ExtractedOIDSymbol.new(frag)
        else
          forward = /^([a-zA-Z0-9-_]+)\(([0-9]+)\)$/.match(frag)

          if forward.nil?
            raise "could not parse oid"
          end

          ExtractedOIDForwardSymbol.new(forward[1], forward[2].to_i32)
        end
      end

      ExtractedOID.new(fragments)
    end

  end

end
