class Carrier
  attr_reader :name, :origin, :loading_time, :capacity

  def initialize(name:, origin:, loading_time: 0, capacity: 1)
    @name = name
    @origin = origin
    @loading_time = loading_time
    @capacity = capacity
  end
end

class Truck < Carrier
end

class Ship < Carrier
end


