module CrSNMP::MIBParser

  abstract class FileResolver
    abstract def load(mib)
  end

  class SimpleFileResolver < FileResolver
    property prefix : String

    def initialize(@prefix)
    end

    def load(file)
      path = @prefix + '/' + file + ".txt"
      File.read path
    end
  end

end
