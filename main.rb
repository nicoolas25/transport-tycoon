$time = 0

$locations = {
  "FACTORY" => ARGV[0].chomp.split(""),
  "PORT"    => [],
  "A"       => [],
  "B"       => [],
}

$carriers = [
  { id: "0", type: "TRUCK", capacity: 1, origin: "FACTORY", cargos: [], location: "FACTORY", at: 0 },
  { id: "1", type: "TRUCK", capacity: 1, origin: "FACTORY", cargos: [], location: "FACTORY", at: 0 },
  { id: "2", type: "SHIP",  capacity: 1, origin: "PORT",    cargos: [], location: "PORT",    at: 0 },
]

$routes = {
  { from: "FACTORY", to: "A",       carrier_type: "TRUCK" } => ->{ { location: "PORT",    at: $time + 1 } },
  { from: "PORT",    to: "FACTORY", carrier_type: "TRUCK" } => ->{ { location: "FACTORY", at: $time + 1 } },
  { from: "FACTORY", to: "B",       carrier_type: "TRUCK" } => ->{ { location: "B",       at: $time + 5 } },
  { from: "B",       to: "FACTORY", carrier_type: "TRUCK" } => ->{ { location: "FACTORY", at: $time + 5 } },
  { from: "PORT",    to: "A",       carrier_type: "SHIP"  } => ->{ { location: "A",       at: $time + 4 } },
  { from: "A",       to: "PORT",    carrier_type: "SHIP"  } => ->{ { location: "PORT",    at: $time + 4 } },
}

def busy?(carrier)
  carrier[:at] > $time
end

def loaded?(carrier)
  carrier[:cargos].any?
end

def at_origin?(carrier)
  carrier[:origin] == carrier[:location]
end

def idle?(carrier)
  stock = $locations[carrier[:origin]]
  cargos = carrier[:cargos]

  at_origin?(carrier) && cargos.empty? && stock.empty?
end

def load_cargos!(carrier)
  stock = $locations[carrier[:location]]
  cargos = stock.shift(carrier[:capacity])
  carrier[:cargos] = cargos
  # puts "LOAD   #{$time} #{carrier.inspect}"
  true
end

def unload_cargos!(carrier)
  stock = $locations[carrier[:location]]
  stock.concat(carrier[:cargos])
  carrier[:cargos] = []
  # puts "UNLOAD #{$time} #{carrier.inspect}"
  true
end

def travel!(carrier, to:)
  carrier.merge!($routes.fetch(
    from: carrier[:location],
    to: to,
    carrier_type: carrier[:type],
  ).call)
  # puts "TRAVEL #{$time} #{carrier.inspect}"
  true
end

def all_cargos_delivered?
  $locations.all? { |location, cargos| cargos.all? { |cargo| cargo == location } } &&
    $carriers.all? { |carrier| carrier[:cargos].empty? }
end

loop do
  loop do
    actions = $carriers.flat_map do |carrier|
      next if busy?(carrier) || idle?(carrier)

      if at_origin?(carrier)
        if loaded?(carrier)
          travel!(carrier, to: carrier[:cargos].first)
        else
          load_cargos!(carrier)
        end
      else
        if loaded?(carrier)
          unload_cargos!(carrier)
        else
          travel!(carrier, to: carrier[:origin])
        end
      end
    end

    break if actions.compact.empty?
  end

  if all_cargos_delivered?
    break
  else
    $time += 1
  end
end

puts $time
