require "./input"

module CrSNMP::Debug

  class DataBuilder

    def build(input : DataType) : DataValue
      do_build input
    end

    private def do_build(input : DataType) : DataValue
      if input.is_a?(CustomDataType)
        do_build input.parent
      elsif input.is_a?(OctetStringDataType)
        user = CrSNMP::Debug.prompt_octet "Podaj OctetString (string): "
        OctetStringDataValue.new user
      elsif input.is_a?(IntegerDataType)
        user = CrSNMP::Debug.prompt_int "Podaj integer: "
        IntegerDataValue.new user
      elsif input.is_a?(BooleanDataType)
        user = CrSNMP::Debug.prompt_bool "Podaj bool (y,true,1): "
        BooleanDataValue.new user
      elsif input.is_a?(NullDataValue)
        NullDataValue.new
      elsif input.is_a?(OIDDataType)
        user = CrSNMP::Debug.prompt_oid "Podaj OID: "
        OIDDataValue.new user
      elsif input.is_a?(ChoiceDataType)
        puts "Wybierz jeden z dostępnych typów"

        input.items.each do |k, v|
          puts k
        end

        choice_type = CrSNMP::Debug.prompt_string "Podaj typ: "
        choice_value = input.items[choice_type]

        out = do_build choice_value
        out.tag = choice_value.tags[0]
        out
      elsif input.is_a?(SequenceDataType)
        items = [] of SequenceDataValue::Item

        input.items.each do |k, v|
          puts "Element struktury " + k
          elem = do_build v
          items << SequenceDataValue::Item.new elem, k
        end

        SequenceDataValue.new items
      elsif input.is_a?(ArrayDataType)
        user = CrSNMP::Debug.prompt_int "Podaj ilość elementów tablicy: "

        items = [] of SequenceDataValue::Item

        0.upto(user - 1) do |i|
          puts "Element #" + i.to_s
          elem = do_build input.item
          items << SequenceDataValue::Item.new elem, "item"
        end

        SequenceDataValue.new items
      else
        raise "Nieznany typ"
      end
    end

  end

end
