require_relative "./lib/transport_tycoon"

map = Map.new(
  locations: [
    factory      = Location.new(name: "FACTORY"),
    port         = Location.new(name: "PORT"),
    wharehouse_a = Location.new(name: "A"),
    wharehouse_b = Location.new(name: "B"),
  ],
  roads: [
    factory_to_wharehouse_b = TruckRoad.new(factory, wharehouse_b, distance: 5),
    factory_to_port         = TruckRoad.new(factory, port, distance: 1),
    port_to_wharehouse_a    = ShipRoad.new(port, wharehouse_a, distance: 4),
  ],
  itineraries: {
    [factory, wharehouse_a] => [port, factory_to_port],
    [wharehouse_a, factory] => [port, port_to_wharehouse_a],

    [factory, wharehouse_b] => [wharehouse_b, factory_to_wharehouse_b],
    [wharehouse_b, factory] => [factory, factory_to_wharehouse_b],

    [factory, port] => [port, factory_to_port],
    [port, factory] => [factory, factory_to_port],

    [port, wharehouse_a] => [wharehouse_a, port_to_wharehouse_a],
    [wharehouse_a, port] => [port, port_to_wharehouse_a],
  },
)

vehicles = [
  truck_1 = Truck.new(name: "1", origin: factory),
  truck_2 = Truck.new(name: "2", origin: factory),
  ship    = Ship.new(name: "1", origin: port),
]

designations = ARGV[0].chomp.split("").map do |name|
  case name
  when "A" then wharehouse_a
  when "B" then wharehouse_b
  else raise
  end
end

cargos = designations.map.with_index { |destination, i| Cargo.new(name: i.to_s, destination: destination) }

state = State.new(
  time: 0,
  map: map,
  carrier_states: vehicles.each_with_object({}) do |vehicle, states|
    states[vehicle] = CarrierState.new(carrier: vehicle, type: :idle, from_time: 0, to_time: 0, place: vehicle.origin, cargo: nil)
  end,
  place_states: {
    factory => PlaceState.new(place: factory, cargos: cargos),
    wharehouse_a => PlaceState.new(place: wharehouse_a, cargos: []),
    wharehouse_b => PlaceState.new(place: wharehouse_b, cargos: []),
    port => PlaceState.new(place: port, cargos: []),
  },
)

simulation = Simulation.new(state: state)

while !simulation.all_cargo_delivered?
  simulation = simulation.step
end

puts simulation.state.time
