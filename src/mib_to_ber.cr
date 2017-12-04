require "./ber/*"
require "./mibparser/extractor/*"
require "./shared/oid"
require "./shared/tags"

include CrSNMP::MIBParser
include CrSNMP::BER
include CrSNMP::Shared

module CrSNMP

  class MIBBERTypeConverter

    def initialize(@global_types : Hash(String, ExtractedType) = {} of String => ExtractedType)
      @resolved = {} of String => DataType
    end

    def convert(extracted : ExtractedType) : DataType
      create_wrapped extracted
    end

    private def create_wrapped(extracted : ExtractedType, default_mode = TaggingMode::Explicit) : CustomDataType
      tag_type = extracted.tag_type
      id = extracted.id

      mode = tag_type.nil? ? default_mode : tag_type
      tag = id.nil? ? nil : Tag.new(id, extracted.tag)
      parent = create_direct extracted

      CustomDataType.new tag, parent, mode, create_restriction(extracted.size), create_restriction(extracted.range)
    end

    private def create_direct(extracted : ExtractedType) : DataType
      if extracted.is_a?(SymbolExtractedType)
        resolve extracted.symbol_name
      elsif extracted.is_a?(PrimitiveExtractedType)
        case extracted.primitive
        when PrimitiveExtractedType::Primitive::OctetString
          OctetStringDataType.new
        when PrimitiveExtractedType::Primitive::Integer
          IntegerDataType.new
        when PrimitiveExtractedType::Primitive::ObjectIdentifier
          OIDDataType.new
        when PrimitiveExtractedType::Primitive::Null
          NullDataType.new
        when PrimitiveExtractedType::Primitive::Boolean
          BooleanDataType.new
        else
          raise "Unknown primitive type"
        end
      elsif extracted.is_a?(ChoiceExtractedType)
        items = {} of String => DataType

        i = 0

        extracted.choices.each do |k, sub|
          items[k] = create_wrapped sub
          i += 1
        end

        ChoiceDataType.new items
      elsif extracted.is_a?(SequenceExtractedType)
        items = {} of String => DataType

        i = 0

        extracted.items.each do |k, sub|
          items[k] = create_wrapped sub
          i += 1
        end

        SequenceDataType.new items
      elsif extracted.is_a?(SequenceOfExtractedType)
        ArrayDataType.new create_wrapped(extracted.item)
      else
        raise "Unconvertable type"
      end
    end

    private def create_restriction(extracted : ExtractedSize | Nil) : Restriction | Nil
      if extracted.nil?
        nil
      elsif extracted.is_a?(RangeExtractedSize)
        RangeRestriction.new extracted.left, extracted.right
      elsif extracted.is_a?(NumberExtractedSize)
        NumberRestriction.new extracted.number
      else
        nil
      end
    end

    private def resolve(symbol : String) : DataType
      if @resolved.has_key? symbol
        @resolved[symbol]
      else
        extracted = resolve_extracted symbol
        ber = create_wrapped extracted
        @resolved[symbol] = ber
      end
    end

    private def resolve_extracted(symbol : String) : ExtractedType
      if @global_types.has_key? symbol
        @global_types[symbol]
      else
        raise "Unresolvable type " + symbol
      end
    end

  end

end
