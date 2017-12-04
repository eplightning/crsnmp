module CrSNMP::Shared

  class ObjectType

    enum Access
      ReadOnly
      ReadWrite
      WriteOnly
      NotAccessible
    end

    enum Status
      Mandatory
      Optional
      Obsolete
      Deprecated
    end

    property access : Access
    property status : Status
    property description : String

    def initialize(@access, @status, @description)

    end

  end

end
