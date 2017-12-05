require "../shared/oid"
require "../shared/tags"
require "./restrictions"
require "./values"
require "./decoder"
require "./encoder"
require "./tag_resolver"

include CrSNMP::Shared

module CrSNMP::BER

  abstract class DataType
    abstract def decode(bytes : Array(UInt8), implicit_tag : Tag | Nil = nil) : DataValue
    abstract def encode(data : DataValue, implicit_tag : Tag | Nil = nil) : Array(UInt8)
    abstract def tags : Array(Tag)

    protected def decode_header(bytes : Array(UInt8), primitive : Bool, final_tag : Tag) : Array(UInt8)
      raw = decode_header_raw bytes

      if raw[:tag] != final_tag || raw[:primitive] != primitive
        raise "Invalid tag or P/C bit"
      end

      left = raw[:header_size]
      right = raw[:header_size] + raw[:length]

      bytes[left..right]
    end

    protected def decode_header_raw(bytes : Array(UInt8)) : NamedTuple(tag: Tag, primitive: Bool, length: Int32, header_size: Int32)
      decoded_tag = Decoder.decode_tag bytes
      decoded_len = Decoder.decode_length bytes[(decoded_tag[0])..-1]

      if decoded_len[1] > (bytes.size - decoded_tag[0] - decoded_len[0])
        raise "Not enough bytes"
      end

      {tag: decoded_tag[1], primitive: decoded_tag[2], length: decoded_len[1], header_size: (decoded_tag[0] + decoded_len[0])}
    end

    protected def encode_content(content : Array(UInt8), primitive : Bool, final_tag : Tag) : Array(UInt8)
      out = Encoder.encode_tag final_tag, primitive
      out.concat Encoder.encode_length content.size
      out.concat content
    end
  end

  abstract class PredefinedDataType < DataType
  end

  abstract class PrimitiveDataType < PredefinedDataType

    def decode(bytes : Array(UInt8), implicit_tag : Tag | Nil = nil) : DataValue
      tag = (implicit_tag.nil? ? primitive_tag : implicit_tag)
      contents = decode_header bytes, true, tag
      decode_primitive contents, tag
    end

    def encode(data : DataValue, implicit_tag : Tag | Nil = nil) : Array(UInt8)
      content = encode_primitive(data)
      final_tag = implicit_tag.nil? ? primitive_tag : implicit_tag
      encode_content content, true, final_tag
    end

    def tags : Array(Tag)
      [primitive_tag]
    end

    abstract def primitive_tag : Tag
    abstract def encode_primitive(data : DataValue) : Array(UInt8)
    abstract def decode_primitive(bytes : Array(UInt8), tag : Tag) : DataValue
  end

  abstract class CompositeDataType < PredefinedDataType
  end

  class SequenceDataType < CompositeDataType
    getter items : Hash(String, DataType)

    def initialize(@items)
    end

    def decode(bytes : Array(UInt8), implicit_tag : Tag | Nil = nil) : DataValue
      final_tag = (implicit_tag.nil? ? SequenceDataType.universal_tag : implicit_tag)
      contents = decode_header bytes, false, final_tag

      items = [] of SequenceDataValue::Item

      @items.each do |k, v|
        raw = decode_header_raw contents
        item_bytes = contents[0...(raw[:length] + raw[:header_size])]
        item_data = v.decode item_bytes
        items << SequenceDataValue::Item.new item_data, k

        contents = contents[(raw[:length] + raw[:header_size])..-1]
      end

      SequenceDataValue.new items, final_tag
    end

    def encode(data : DataValue, implicit_tag : Tag | Nil = nil) : Array(UInt8)
      if data.is_a?(SequenceDataValue)
        content = [] of UInt8

        if data.items.size != @items.size
          raise "data.items.size != @items.size"
        end

        i = 0
        @items.each do |k, v|
          content.concat v.encode(data.items[i].data)
          i += 1
        end

        final_tag = implicit_tag.nil? ? SequenceDataType.universal_tag : implicit_tag
        encode_content content, false, final_tag
      else
        raise "Invalid data, expected SequenceDataValue"
      end
    end

    def tags : Array(Tag)
      [SequenceDataType.universal_tag]
    end

    def self.universal_tag : Tag
      Tag.new 16, TagClass::Universal
    end
  end

  class ArrayDataType < CompositeDataType
    getter item : DataType

    def initialize(@item)
      @resolver = TagResolver.new @item
    end

    def decode(bytes : Array(UInt8), implicit_tag : Tag | Nil = nil) : DataValue
      final_tag = (implicit_tag.nil? ? ArrayDataType.universal_tag : implicit_tag)
      contents = decode_header bytes, false, final_tag

      items = [] of SequenceDataValue::Item

      while contents.size > 0
        raw = decode_header_raw contents

        resolved_type = @resolver.resolve? raw[:tag]

        if resolved_type.nil?
          raise "Invalid sequence item tag"
        end

        item_bytes = contents[0...(raw[:length] + raw[:header_size])]
        item_data = resolved_type[1].decode item_bytes
        items << SequenceDataValue::Item.new item_data, resolved_type[0]

        contents = contents[(raw[:length] + raw[:header_size])..-1]
      end

      SequenceDataValue.new items, final_tag
    end

    def encode(data : DataValue, implicit_tag : Tag | Nil = nil) : Array(UInt8)
      if data.is_a?(SequenceDataValue)
        content = [] of UInt8

        data.items.each do |i|
          resolved_type = @resolver.resolve? i.data.tag

          if resolved_type.nil?
            raise "Invalid sequence item tag"
          end

          content.concat resolved_type[1].encode(i.data)
        end

        final_tag = implicit_tag.nil? ? ArrayDataType.universal_tag : implicit_tag
        encode_content content, false, final_tag
      else
        raise "Invalid data, expected SequenceDataValue"
      end
    end

    def self.universal_tag : Tag
      Tag.new 16, TagClass::Universal
    end

    def tags : Array(Tag)
      [ArrayDataType.universal_tag]
    end
  end

  class ChoiceDataType < CompositeDataType
    getter items : Hash(String, DataType)

    def initialize(@items)
      @resolver = TagResolver.new @items
    end

    def decode(bytes : Array(UInt8), implicit_tag : Tag | Nil = nil) : DataValue
      if !implicit_tag.nil?
        raise "Choice cannot be implicit"
      end

      header = decode_header_raw bytes

      resolved_type = @resolver.resolve? header[:tag]

      if resolved_type.nil?
        raise "Invalid choice item tag"
      end

      resolved_type[1].decode bytes, nil
    end

    def encode(data : DataValue, implicit_tag : Tag | Nil = nil) : Array(UInt8)
      if !implicit_tag.nil?
        raise "Choice cannot be implicit"
      end

      resolved_type = @resolver.resolve? data.tag

      if resolved_type.nil?
        raise "Invalid choice item tag"
      end

      resolved_type[1].encode data, implicit_tag
    end

    def tags : Array(Tag)
      output = [] of Tag

      @items.each do |k, v|
        output.concat v.tags
      end

      output
    end
  end

  class IntegerDataType < PrimitiveDataType

    def encode_primitive(data : DataValue) : Array(UInt8)
      if data.is_a?(IntegerDataValue)
        Encoder.encode_int data.val
      else
        raise "Invalid data, expected IntegerDataValue"
      end
    end

    def decode_primitive(bytes : Array(UInt8), tag : Tag) : DataValue
      IntegerDataValue.new Decoder.decode_int(bytes), tag
    end

    def primitive_tag : Tag
      IntegerDataType.universal_tag
    end

    def self.universal_tag : Tag
      Tag.new 2, TagClass::Universal
    end

    def to_s
      "integer"
    end
  end

  class OIDDataType < PrimitiveDataType

    def encode_primitive(data : DataValue) : Array(UInt8)
      if data.is_a?(OIDDataValue)
        Encoder.encode_oid data.val
      else
        raise "Invalid data, expected OIDDataValue"
      end
    end

    def decode_primitive(bytes : Array(UInt8), tag : Tag) : DataValue
      OIDDataValue.new Decoder.decode_oid(bytes), tag
    end

    def primitive_tag : Tag
      OIDDataType.universal_tag
    end

    def self.universal_tag : Tag
      Tag.new 6, TagClass::Universal
    end

    def to_s
      "oid"
    end
  end

  class BooleanDataType < PrimitiveDataType

    def encode_primitive(data : DataValue) : Array(UInt8)
      if data.is_a?(BooleanDataValue)
        Encoder.encode_bool data.val
      else
        raise "Invalid data, expected BooleanDataValue"
      end
    end

    def decode_primitive(bytes : Array(UInt8), tag : Tag) : DataValue
      BooleanDataValue.new Decoder.decode_bool(bytes), tag
    end

    def primitive_tag : Tag
      BooleanDataType.universal_tag
    end

    def self.universal_tag : Tag
      Tag.new 1, TagClass::Universal
    end

    def to_s
      "boolean"
    end
  end

  class NullDataType < PrimitiveDataType

    def encode_primitive(data : DataValue) : Array(UInt8)
      if data.is_a?(NullDataValue)
        [] of UInt8
      else
        raise "Invalid data, expected NullDataValue"
      end
    end

    def decode_primitive(bytes : Array(UInt8), tag : Tag) : DataValue
      NullDataValue.new tag
    end

    def primitive_tag : Tag
      NullDataType.universal_tag
    end

    def self.universal_tag : Tag
      Tag.new 5, TagClass::Universal
    end

    def to_s
      "null"
    end
  end

  class OctetStringDataType < PrimitiveDataType

    def decode(bytes : Array(UInt8), implicit_tag : Tag | Nil = nil) : DataValue
      final_tag = (implicit_tag.nil? ? primitive_tag : implicit_tag)
      raw = decode_header_raw bytes

      if raw[:tag] != final_tag
        raise "Invalid tag"
      end

      left = raw[:header_size]
      right = raw[:header_size] + raw[:length]
      bytes = bytes[left..right]

      if raw[:primitive]
        OctetStringDataValue.new bytes, final_tag
      else
        OctetStringDataValue.new decode_constructed(bytes), final_tag
      end
    end

    private def decode_constructed(bytes : Array(UInt8)) : Array(UInt8)
      output = [] of UInt8

      while bytes.size > 0
        raw = decode_header_raw bytes

        if raw[:tag] != primitive_tag
          raise "Constructed OctetString can only contain OctetStrings"
        end

        left = raw[:header_size]
        right = raw[:header_size] + raw[:length]
        current_bytes = bytes[left..right]

        if bytes.size > right
          bytes = bytes[right..-1]
        else
          bytes = [] of UInt8
        end

        if raw[:primitive]
          output.concat current_bytes
        else
          output.concat decode_constructed(bytes)
        end
      end

      output
    end

    def encode_primitive(data : DataValue) : Array(UInt8)
      if data.is_a?(OctetStringDataValue)
        data.val
      else
        raise "Invalid data, expected OctetStringDataValue"
      end
    end

    def decode_primitive(bytes : Array(UInt8), tag : Tag) : DataValue
      OctetStringDataValue.new bytes, tag
    end

    def primitive_tag : Tag
      OctetStringDataType.universal_tag
    end

    def self.universal_tag : Tag
      Tag.new 4, TagClass::Universal
    end

    def to_s
      "octetstring"
    end
  end

  class CustomDataType < DataType
    getter parent : DataType
    getter type_tag : Tag | Nil
    getter tagging_mode : TaggingMode
    getter restrictions : Restrictions

    def initialize(@type_tag, @parent, @tagging_mode = TaggingMode::Implicit, sizer = nil, valuer = nil)
      @restrictions = Restrictions.new sizer, valuer
    end

    protected def do_decode(bytes : Array(UInt8), final_tag : Tag | Nil = nil) : DataValue
      if final_tag.nil?
        parent.decode bytes
      else
        if @tagging_mode == TaggingMode::Implicit
          parent.decode bytes, final_tag
        else
          contents = decode_header bytes, false, final_tag

          parent.decode contents
        end
      end
    end

    def decode(bytes : Array(UInt8), implicit_tag : Tag | Nil = nil) : DataValue
      final_tag = (implicit_tag.nil? ? @type_tag : implicit_tag)

      out = do_decode bytes, final_tag

      if !final_tag.nil?
        out.tag = final_tag
      end

      validation = out.passes_restrictions @restrictions

      if !validation.nil?
        raise validation
      end

      out
    end

    def encode(data : DataValue, implicit_tag : Tag | Nil = nil) : Array(UInt8)
      validation = data.passes_restrictions @restrictions

      if !validation.nil?
        raise validation
      end

      tag = @type_tag

      if tag.nil?
        parent.encode data, implicit_tag
      else
        final_tag = (implicit_tag.nil? ? tag : implicit_tag)

        if @tagging_mode == TaggingMode::Implicit
          parent.encode data, final_tag
        else
          parent_encoded = parent.encode (data.is_a?(TagWrapDataValue) ? data.wrapped : data)
          encode_content parent_encoded, false, final_tag
        end
      end
    end

    def tags : Array(Tag)
      tag = @type_tag

      if tag.nil?
        parent.tags
      else
        [tag]
      end
    end
  end

end
