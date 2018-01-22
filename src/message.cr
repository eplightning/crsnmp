require "./shared/oid"
require "./ber/values"

include CrSNMP::Shared

module CrSNMP

  enum PDUType
    GetRequest = 0
    GetNextRequest = 1
    GetResponse = 2
    SetRequest = 3
  end

  class PDU
    property pdu_type : PDUType
    property request : Int64
    property error_status : Int64
    property error_index : Int64
    property bindings : Hash(OID, BER::DataValue)

    def initialize
      @pdu_type = PDUType::GetRequest
      @request = 0_i64
      @error_status = 0_i64
      @error_index = 0_i64
      @bindings = {} of OID => BER::DataValue
    end
  end

  class Message

    property version : Int64
    property community : String
    property pdu : PDU

    def to_s(io : IO) : Nil
      inspect(io)
    end

    def initialize
      @version = 0_i64
      @community = ""
      @pdu = PDU.new
    end

    def self.from_data(data : BER::DataValue) : Message
      msg = Message.new

      # Message
      data_msg = data.as(BER::SequenceDataValue)
      msg.version = data_msg.items[0].data.as(IntegerDataValue).val
      community_bytes = data_msg.items[1].data.as(OctetStringDataValue)
      msg.community = community_bytes.to_s

      # PDU
      pdu = data_msg.items[2].data.as(BER::SequenceDataValue)
      msg.pdu.pdu_type = PDUType.new(pdu.tag.index)
      msg.pdu.request = pdu.items[0].data.as(IntegerDataValue).val
      msg.pdu.error_status = pdu.items[1].data.as(IntegerDataValue).val
      msg.pdu.error_index = pdu.items[2].data.as(IntegerDataValue).val

      # VarBindList
      bindings = pdu.items[3].data.as(BER::SequenceDataValue)
      bindings.items.each do |v|
        binding_pair = v.data.as(BER::SequenceDataValue)
        key = binding_pair.items[0].data.as(OIDDataValue).val
        value = binding_pair.items[1].data
        msg.pdu.bindings[key] = value
      end

      msg
    end

  end

end
