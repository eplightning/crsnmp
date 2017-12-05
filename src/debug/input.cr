require "readline"

module CrSNMP::Debug

  def self.prompt_int(txt : String) : Int64
    str = Readline.readline(txt)

    if str.nil?
      raise "Readline returned nil"
    end

    str.to_i64
  end

  def self.prompt_bool(txt : String) : Bool
    str = Readline.readline(txt)

    if str.nil?
      raise "Readline returned nil"
    end

    str == "1" || str == "true" || str == "y" || str == "t" || str == "yes"
  end

  def self.prompt_octet(txt : String) : Array(UInt8)
    str = Readline.readline(txt)

    if str.nil?
      raise "Readline returned nil"
    end

    str.bytes
  end

  def self.prompt_oid(txt : String) : OID
    str = Readline.readline(txt)

    if str.nil?
      raise "Readline returned nil"
    end

    frags = str.split(".").map do |s|
      OIDFragment.new s.to_i32
    end

    OID.new nil, frags
  end



end
