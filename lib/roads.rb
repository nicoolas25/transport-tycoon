class Road
  attr_reader :distance

  def initialize(location_a, location_b, distance: 1)
    @locations = [location_a, location_b].sort_by(&:object_id)
    @distance = distance
  end

  def accepts?(carrier:)
    raise NotImplementedError
  end
end

class TruckRoad < Road
  def accepts?(carrier:)
    carrier.is_a?(Truck)
  end
end

class ShipRoad < Road
  def accepts?(carrier:)
    carrier.is_a?(Ship)
  end
end
