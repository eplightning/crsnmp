module CrSNMP::Debug

  def self.print_binary(arr : Array(UInt8))
    arr.each do |i|
      bitstring = (i.to_s 2)

      pad = "0" * (8 - bitstring.size)

      puts pad + bitstring + " [" + i.to_s + ']'
    end
  end

  def self.get_ber_type(tree : Hash(String, TreeNode), oid : String) : DataType
    obj = tree[oid]
    syntax = obj.syntax
    if syntax.nil?
      raise "nie ma węzła"
    else
      syntax
    end
  end

end
