require "./extractor/*"

module CrSNMP::MIBParser

  REGEX_MIB = /(?<filename>[a-zA-Z0-9-_]+)\s*DEFINITIONS\s*::=\s*BEGIN\s*(IMPORTS\s*(?<imports>.+?)\s*;)?\s*(EXPORTS\s*(?<exports>.+?)\s*;)?\s*(?<body>.*)\s*END\s*/m
  REGEX_COMMENT = /--[^\n]*$/m
  REGEX_MACRO = /[A-Z-]+\s+MACRO\s*::=\s*BEGIN.+?END/m
  REGEX_OID = /(?<oid>\{\s*([a-zA-Z0-9-_](\([0-9]+\))?+\s?)+\s*\})/
  REGEX_OBJECT_TYPE = /(?<identifier>[a-zA-Z0-9]+)\s+OBJECT-TYPE\s+SYNTAX\s+(?<syntax>.+?)\s+(ACCESS|MAX-ACCESS)\s+(?<access>read-only|read-write|write-only|not-accessible)\s+STATUS\s+(?<status>mandatory|optional|obsolete|deprecated)\s+DESCRIPTION\s+"(?<description>.+?)"\s+(INDEX\s+\{\s*(?<index>[\sa-zA-Z0-9,]+?)\s*\})?\s+::=\s+(?<oid>\{\s*([a-zA-Z0-9-_](\([0-9]+\))?+\s?)+\s*\})/m
  REGEX_OBJECT_ID = /(?<identifier>[a-zA-Z0-9-_]+?)\s+OBJECT\sIDENTIFIER\s+::=\s+(?<oid>\{\s*([a-zA-Z0-9-_](\([0-9]+\))?+\s?)+\s*\})/m
  REGEX_TYPE = /(?<identifier>[a-zA-Z0-9]+)\s+::=\s+(?<rightHand>(\[((APPLICATION|UNIVERSAL|CONTEXT-SPECIFIC|PRIVATE)\s+)?([0-9]+)\]\s*)?((IMPLICIT|EXPLICIT)\s+)?((SEQUENCE\s+\{.+?\}|CHOICE\s+\{.+?\}|OCTET STRING|INTEGER(\s+\{.+?\})?|BOOLEAN|NULL|OBJECT IDENTIFIER|SEQUENCE OF [a-zA-Z0-9-_]+|[a-zA-Z0-9-_]+))\s*(\(\s*([0-9-]+\.\.[0-9-]+)\s*\))?\s*(\(\s*(SIZE|size|Size)\s*\((.+?)\)\s*\))?)/m
  REGEX_IMPORT_LINE = /(?<identifiers>[a-zA-Z0-9,\s-_]+?)\sFROM\s+(?<filename>[a-zA-Z0-9-_]+)/m
  REGEX_TYPE_RIGHTHAND = /(\[((?<visibility>APPLICATION|UNIVERSAL|CONTEXT-SPECIFIC|PRIVATE)\s+)?(?<type_id>[0-9]+)\]\s*)?((?<implicit>IMPLICIT|EXPLICIT)\s+)?(?<type>(SEQUENCE\s+\{.+?\}|CHOICE\s+\{.+?\}|OCTET STRING|INTEGER(\s+\{.+?\})?|BOOLEAN|NULL|OBJECT IDENTIFIER|SEQUENCE OF [a-zA-Z0-9-_]+|[a-zA-Z0-9-_]+))\s*(\(\s*(?<range>[0-9-]+\.\.[0-9-]+)\s*\))?\s*(\(\s*(SIZE|size|Size)\s*\((?<size>.+?)\)\s*\))?/m

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
      symbols = extract_symbols name, body

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

    private def extract_symbols(mib : String, body : String) : Hash(String, MIBSymbol)
      symbols = {} of String => MIBSymbol

      # identifier
      body.scan(REGEX_OBJECT_ID) do |id_match|
        id = id_match["identifier"]
        oid = id_match["oid"]
        symbols[id] = ObjectIdentifierSymbol.new(id, mib, parse_oid(oid))
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

        symbols[id] = ObjectTypeSymbol.new(id, mib, parse_type(syntax), access, status, description, parse_oid(oid), index)
      end
      body = body.gsub REGEX_OBJECT_TYPE, ""

      # types
      body.scan(REGEX_TYPE) do |id_match|
        id = id_match["identifier"]
        definition = id_match["rightHand"]

        symbols[id] = TypeDefinitionSymbol.new(id, mib, parse_type(definition))
      end

      symbols
    end

    private def parse_type(definition : String) : ExtractedType
      parsed = REGEX_TYPE_RIGHTHAND.match definition

      if !parsed.nil?
        raw_id = parsed["type_id"]?
        tag = parsed["visibility"]?
        tag_type = parsed["implicit"]?
        size = parse_size(parsed["size"]?)
        range = parse_size(parsed["range"]?)

        id = raw_id.nil? ? nil : raw_id.to_i32

        main = parsed["type"]

        if main == "OCTET STRING" || main == "INTEGER" ||
          main == "NULL" || main == "OBJECT IDENTIFIER" || main == "BOOLEAN"
          PrimitiveExtractedType.new main, id, tag, tag_type, size, range
        elsif main.starts_with? "INTEGER "
          PrimitiveExtractedType.new "INTEGER", id, tag, tag_type, size, range
        elsif /^[a-zA-Z0-9-_]+$/.match(main)
          SymbolExtractedType.new main, id, tag, tag_type, size, range
        else
          sequence_of = /^SEQUENCE OF ([a-zA-Z0-9-_]+)$/.match(main)
          sequence = /^SEQUENCE\s+\{(.+?)\}$/m.match(main)
          choice = /^CHOICE\s+\{(.+?)\}$/m.match(main)

          if !sequence_of.nil?
            subtype = parse_type sequence_of[1]
            SequenceOfExtractedType.new(subtype)
          elsif !sequence.nil?
            SequenceExtractedType.new parse_subtypes(sequence[1])
          elsif !choice.nil?
            ChoiceExtractedType.new parse_subtypes(choice[1])
          else
            UnknownExtractedType.new definition
          end
        end
      else
        UnknownExtractedType.new definition
      end
    end

    private def parse_subtypes(data : String) : Hash(String, ExtractedType)
      raw_items = extract_identifiers data

      output = {} of String => ExtractedType

      raw_items.each do |raw_item|
        raw_item_split = raw_item.split 2

        if raw_item_split.size == 2
          output[raw_item_split[0]] = parse_type(raw_item_split[1])
        end
      end

      output
    end

    private def parse_size(size : String | Nil): ExtractedSize | Nil
      if size.nil?
        nil
      else
        if /^-?[0-9]+$/.match(size)
          NumberExtractedSize.new(size.to_i64)
        else
          range_match = /^(-?[0-9]+)\.\.(-?[0-9]+)$/.match(size)

          if !range_match.nil?
            RangeExtractedSize.new(range_match[1].to_i64, range_match[2].to_i64)
          else
            raise "Unparsable size " + size
          end
        end
      end
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
