require "./shared/*"
require "./object_tree"
require "./ber/values"
require "socket"
require "./message"

module CrSNMP

  struct DecodedPacket
    property message : Message
    property sender : Socket::IPAddress

    def initialize(@message, @sender)

    end
  end

  class Server

    def initialize(@tree : RootTreeNode, @data : DataManager)
      @msg_chan = Channel(DecodedPacket).new(10)
      @sig_chan = Channel(Signal).new(10)
    end

    def run
      socket = UDPSocket.new
      msg_type = @tree.types["Message"]

      spawn do
        socket.bind "0.0.0.0", 161
        recv_fiber socket
      end

      Signal::INT.trap do
        @sig_chan.send Signal::INT
      end

      loop do
        select
        when sig = @sig_chan.receive
          break
        when msg = @msg_chan.receive
          response = if msg.message.pdu.pdu_type == PDUType::GetRequest
            handle_get(msg.message)
          elsif msg.message.pdu.pdu_type == PDUType::SetRequest
            handle_set(msg.message)
          else
            nil
          end

          if !response.nil?
            puts "sending response"
            send_message socket, response, msg.sender
          else
            puts "no response (unsupported message)"
          end
        end
      end

      socket.close
    end

    private def handle_get(message : Message) : Message | Nil
      new_message = Message.as_response_to(message)

      message.pdu.bindings.each do |oid, value|
        our_value = @data.get oid
        new_message.pdu.bindings[oid] = our_value.nil? ? NullDataValue.new : our_value
      end

      new_message
    end

    private def handle_set(message : Message) : Message | Nil
      new_message = Message.as_response_to(message)

      message.pdu.bindings.each do |oid, value|
        success = @data.set oid, value
        puts success
        our_value = @data.get oid
        new_message.pdu.bindings[oid] = our_value.nil? ? NullDataValue.new : our_value
      end

      new_message
    end

    private def send_message(socket : UDPSocket, message : Message, addr : Socket::IPAddress)
      msg_type = @tree.types["Message"]

      encoded_message = msg_type.encode message.to_data
      slice = Slice.new encoded_message.to_unsafe, encoded_message.size

      socket.send slice, addr
    end

    private def recv_fiber(socket : UDPSocket)
      msg_type = @tree.types["Message"]

      while !socket.closed?
        begin
          raw_message, addr = socket.receive

          decoded_message = msg_type.decode raw_message.bytes
          puts decoded_message

          @msg_chan.send DecodedPacket.new(Message.from_data(decoded_message), addr)
        rescue ex : Errno
          # ...
        rescue ex : Exception
          # ...
          puts ex
        end
      end

      puts "UDP receive fiber finished"
    end

  end

end
