class Carrier
  attr_reader :name, :origin, :loading_time

  def initialize(name:, origin:, loading_time: 0)
    @name = name
    @origin = origin
    @loading_time = loading_time
  end
end

class Truck < Carrier
end

class Ship < Carrier
end


