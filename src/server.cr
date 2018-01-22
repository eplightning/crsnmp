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

    def initialize(@tree : RootTreeNode)
      @msg_chan = Channel(DecodedPacket).new(10)
      @sig_chan = Channel(Signal).new(10)
    end

    def run
      socket = UDPSocket.new

      spawn do
        socket.bind "localhost", 161
        recv_fiber socket
      end

      Signal::INT.trap do
        @sig_chan.send Signal::INT
      end

      loop do
        select
        when sig = @sig_chan.receive
          puts "signal"
          break
        when msg = @msg_chan.receive
          puts "msg"

          message = msg.message
          puts message

          puts msg.sender
        end
      end

      socket.close
    end

    private def recv_fiber(socket : UDPSocket)
      msg_type = @tree.types["Message"]

      while !socket.closed?
        begin
          raw_message, addr = socket.receive

          decoded_message = msg_type.decode raw_message.bytes

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
