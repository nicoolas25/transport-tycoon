require "json"

$time = 0

$locations = {
  "FACTORY" => ARGV[0].chomp.split(""),
  "PORT"    => [],
  "A"       => [],
  "B"       => [],
}

$carriers = [
  { id: "0", type: "TRUCK", capacity: 1, loading_duration: 0, origin: "FACTORY", cargos: [], location: "FACTORY", at: 0 },
  { id: "1", type: "TRUCK", capacity: 1, loading_duration: 0, origin: "FACTORY", cargos: [], location: "FACTORY", at: 0 },
  { id: "2", type: "SHIP",  capacity: 4, loading_duration: 1, origin: "PORT",    cargos: [], location: "PORT",    at: 0 },
]

$routes = {
  { from: "FACTORY", to: "A",       carrier_type: "TRUCK" } => ->{ { location: "PORT",    at: $time + 1 } },
  { from: "PORT",    to: "FACTORY", carrier_type: "TRUCK" } => ->{ { location: "FACTORY", at: $time + 1 } },
  { from: "FACTORY", to: "B",       carrier_type: "TRUCK" } => ->{ { location: "B",       at: $time + 5 } },
  { from: "B",       to: "FACTORY", carrier_type: "TRUCK" } => ->{ { location: "FACTORY", at: $time + 5 } },
  { from: "PORT",    to: "A",       carrier_type: "SHIP"  } => ->{ { location: "A",       at: $time + 6 } },
  { from: "A",       to: "PORT",    carrier_type: "SHIP"  } => ->{ { location: "PORT",    at: $time + 6 } },
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

def publish(event_name, carrier, location: nil, time: nil)
  puts JSON.generate(
    event: event_name,
    time: time || $time,
    duration: carrier[:at] - $time,
    transport_id: carrier[:id],
    kind: carrier[:type],
    location: location || carrier[:location],
    destination: carrier[:location],
    cargo: carrier[:cargos].map do |cargo|
      {
        cargo_id: cargo.object_id,
        destination: cargo,
        origin: "FACTORY",
      }
    end,
  )
  true
end

def load_cargos!(carrier)
  stock = $locations[carrier[:location]]
  cargos = stock.shift(carrier[:capacity])
  carrier[:at] = $time + carrier[:loading_duration]
  carrier[:cargos] = cargos
  publish("LOAD", carrier)
end

def unload_cargos!(carrier)
  stock = $locations[carrier[:location]]
  stock.concat(carrier[:cargos])
  carrier[:at] = $time + carrier[:loading_duration]
  carrier[:cargos] = []
  publish("UNLOAD", carrier)
end

def travel!(carrier, to:)
  from = carrier[:location]
  carrier.merge!($routes.fetch(from: from, to: to, carrier_type: carrier[:type]).call)
  publish("DEPART", carrier, location: from)
  publish("ARRIVE", carrier, time: carrier[:at])
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
