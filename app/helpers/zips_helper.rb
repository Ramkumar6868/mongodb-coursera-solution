module ZipsHelper
  def toZip(value)
    return value.is_a?(Zip) ? value : Zip.new(value)
  end
end
