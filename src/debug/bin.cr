module CrSNMP::Debug

  def self.print_binary(arr : Array(UInt8))
    arr.each do |i|
      bitstring = (i.to_s 2)

      pad = "0" * (8 - bitstring.size)

      puts pad + bitstring + " [" + i.to_s + ']'
    end
  end

end
