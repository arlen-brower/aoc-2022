defmodule DayNineteen do
  @max_rounds 24

  @test_blueprint_one %{
    id: 1,
    ore: %{ore: 4, clay: 0, obsidian: 0},
    clay: %{ore: 2, clay: 0, obsidian: 0},
    obsidian: %{ore: 3, clay: 14, obsidian: 0},
    geode: %{ore: 2, clay: 0, obsidian: 7}
  }
  @test_blueprint_two %{
    id: 2,
    ore: %{ore: 2, clay: 0, obsidian: 0},
    clay: %{ore: 3, clay: 0, obsidian: 0},
    obsidian: %{ore: 3, clay: 8, obsidian: 0},
    geode: %{ore: 3, clay: 0, obsidian: 12}
  }

  @type path() :: String.t()
  @type round() :: integer()
  @type robot_pop() :: integer()
  @type resource() :: integer()
  @type build_queue() :: list(robot_job())
  @type cost() :: %{ore: resource(), clay: resource(), obsidian: resource()}
  @type resouce_type() :: :ore | :clay | :obsidian | :geode | nil
  @type robot_job() :: :ore | :clay | :obsidian | :geode | nil
  @type robot_map() :: %{
          ore: robot_pop(),
          clay: robot_pop(),
          obsidian: robot_pop(),
          geode: robot_pop()
        }
  @type blueprint_string() :: String.t()
  @type blueprint() :: %{ore: cost(), clay: cost(), obsidian: cost(), geode: cost()}
  @type game_state() :: %{
          time: round(),
          ore: resource(),
          clay: resource(),
          obsidian: resource(),
          geode: resource(),
          robots: robot_map(),
          building: build_queue(),
          blueprint: blueprint(),
          options: list(robot_job())
        }

  @spec run(path()) :: [part_one: integer()]
  def run(file_path \\ "test_input") do
    register()

    blueprints =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_line/1)

    blueprints
    |> Enum.each(&spawn(fn -> begin_simulation(&1) end))

    results = get_messages(length(blueprints), [])

    part_one =
      results
      |> Enum.map(fn %{blueprint: blu, geode: geo} -> blu.id * geo end)
      |> Enum.sum()

    [part_one: part_one, results: results]
    part_one
  end

  @spec begin_simulation(blueprint()) :: game_state()
  def begin_simulation(blueprint) do
    game_state = %{
      time: 24,
      ore: 0,
      clay: 0,
      obsidian: 0,
      geode: 0,
      robots: %{ore: 1, clay: 0, obsidian: 0, geode: 0},
      path: [],
      building: [nil],
      blueprint: blueprint,
      options: []
    }

    result = do_round(game_state)

    send(:parent, result)
  end

  @spec do_round(game_state()) :: game_state()
  def do_round(%{time: 0} = game_state) do
    game_state
    |> cache_state()
  end

  def do_round(game_state) do
    game_state
    |> finish_robot(game_state.building)
    |> add_build_options()
    |> collect_resources()
    |> depth_first_build()
  end

  def compress_state(%{
        ore: ore,
        clay: clay,
        obsidian: obs,
        time: time,
        geode: geo,
        robots: robots,
        path: path,
        options: options,
        blueprint: bp
      }) do
    %{
      ore: ore,
      clay: clay,
      obsidian: obs,
      geode: geo,
      # time: time,
      # path: path,
      # options: options,
      # robots: robots,
      blueprint: bp
    }
  end

  def cache_state(
        %{
          geode: geo
        } = game_state
      ) do
    comp = compress_state(game_state)

    # :ets.insert(
    #  __MODULE__,
    #  {comp, geo}
    # )

    game_state
  end

  def get_cached_state(game_state) do
    comp = compress_state(game_state)

    :ets.lookup(__MODULE__, comp)
  end

  @spec depth_first_build(game_state()) :: game_state()
  def depth_first_build(game_state) do
    best_result =
      game_state.options
      |> Enum.map(fn robot_type ->
        new_state =
          game_state
          |> build_robot(robot_type)
          |> add_time()

        case get_cached_state(new_state) do
          [] ->
            do_round(new_state)

          [{cached_state, geodes}] ->
            Map.put(cached_state, :geode, geodes)
        end
      end)
      |> Enum.max_by(fn %{geode: geodes} -> geodes end)

    Map.put(game_state, :geode, best_result.geode)
    |> cache_state()

    best_result
  end

  @spec add_time(game_state()) :: game_state()
  def add_time(game_state) do
    Map.put(game_state, :time, game_state.time - 1)
  end

  @spec build_robot(game_state(), robot_job()) :: game_state()
  def build_robot(game_state, nil) do
    Map.put(game_state, :building, game_state.building ++ [nil])
    |> Map.put(:path, [nil | game_state.path])
  end

  def build_robot(game_state, type) do
    cost = game_state.blueprint[type]

    game_state
    |> remove_resources(:ore, cost.ore)
    |> remove_resources(:clay, cost.clay)
    |> remove_resources(:obsidian, cost.obsidian)
    |> begin_build(type)
  end

  @spec begin_build(game_state(), robot_job()) :: game_state()
  def begin_build(game_state, type) do
    Map.put(game_state, :building, game_state.building ++ [type])
    |> Map.put(:path, [type | game_state.path])
  end

  @spec collect_resources(game_state()) :: game_state()
  def collect_resources(game_state) do
    game_state
    |> add_resource(:ore, game_state.robots.ore)
    |> add_resource(:clay, game_state.robots.clay)
    |> add_resource(:obsidian, game_state.robots.obsidian)
    |> add_resource(:geode, game_state.robots.geode)
  end

  @spec remove_resources(game_state(), resouce_type(), resource()) :: game_state()
  def remove_resources(game_state, type, amount), do: add_resource(game_state, type, -amount)

  @spec add_resource(game_state(), resouce_type(), resource()) :: game_state()
  def add_resource(game_state, type, amount) do
    Map.put(game_state, type, game_state[type] + amount)
  end

  @spec finish_robot(game_state(), build_queue()) :: game_state()
  def finish_robot(game_state, [nil | tail]), do: Map.put(game_state, :building, tail)

  def finish_robot(game_state, [head | tail]) do
    game_state
    |> Map.put(:building, tail)
    |> Map.put(:robots, Map.put(game_state.robots, head, game_state.robots[head] + 1))
  end

  @spec add_build_options(game_state()) :: game_state()
  def add_build_options(game_state) do
    new_state =
      game_state
      |> Map.put(:options, [nil])
      |> add_robot_option(:ore)
      |> add_robot_option(:clay)
      |> add_robot_option(:obsidian)
      |> add_robot_option(:geode)
      |> prune_options()

    new_state
  end

  @spec prune_options(game_state()) :: game_state()
  def prune_options(game_state) do
    options = game_state.options

    pruned =
      cond do
        :geode in options ->
          [:geode]

        true ->
          options
      end

    # take(2) makes it run much faster, but fails for some inputs
    Map.put(game_state, :options, pruned |> Enum.take(2))
  end

  @spec add_robot_option(game_state(), robot_job()) :: game_state()
  def add_robot_option(game_state, robot_type) do
    options = game_state.options

    at_capacity =
      case robot_type do
        :obsidian ->
          game_state.blueprint.geode.obsidian == game_state.robots.obsidian or
            game_state.time <= 1

        :clay ->
          game_state.blueprint.obsidian.clay == game_state.robots.clay or game_state.time <= 2

        :ore ->
          (game_state.blueprint.clay.ore <= game_state.robots.ore and
             game_state.blueprint.obsidian.ore <= game_state.robots.ore and
             game_state.blueprint.geode.ore <= game_state.robots.ore) or
            game_state.time <= 1

        _ ->
          false
      end

    case !at_capacity and
           is_buildable?(
             game_state.blueprint,
             game_state.ore,
             game_state.clay,
             game_state.obsidian,
             robot_type
           ) do
      true ->
        Map.put(game_state, :options, [robot_type | options])

      false ->
        game_state
    end
  end

  def is_buildable?(blueprint, ore, clay, obsidian, robot_type) do
    blueprint[robot_type].ore <= ore and
      blueprint[robot_type].clay <= clay and
      blueprint[robot_type].obsidian <= obsidian
  end

  @spec parse_line(blueprint_string()) :: blueprint()
  def parse_line(blueprint_string) do
    pattern =
      ~r/Blueprint (\d+): Each ore robot costs (\d+) ore. Each clay robot costs (\d+) ore. Each obsidian robot costs (\d+) ore and (\d+) clay. Each geode robot costs (\d+) ore and (\d+) obsidian./

    [id, orebot, claybot, obs_ore, obs_clay, geo_ore, geo_obs] =
      pattern
      |> Regex.run(blueprint_string, capture: :all_but_first)
      |> Enum.map(&String.to_integer/1)

    %{
      id: id,
      ore: %{ore: orebot, clay: 0, obsidian: 0},
      clay: %{ore: claybot, clay: 0, obsidian: 0},
      obsidian: %{ore: obs_ore, clay: obs_clay, obsidian: 0},
      geode: %{ore: geo_ore, clay: 0, obsidian: geo_obs}
    }
  end

  def test_sim() do
    register()
    blueprints = [@test_blueprint_one, @test_blueprint_two]
    Enum.each(blueprints, &spawn(fn -> begin_simulation(&1) end))

    get_messages(length(blueprints), [])
    |> Enum.map(fn %{blueprint: blu, geode: geo} -> blu.id * geo end)
    |> Enum.sum()
  end

  def get_messages(0, messages), do: messages

  def get_messages(number, messages) do
    new_messages =
      receive do
        game_state ->
          IO.puts("ID #{game_state.blueprint.id} returned #{game_state.geode} geodes")
          [game_state | messages]
      end

    get_messages(number - 1, new_messages)
  end

  def register() do
    pid = self()
    IO.puts("Creating :ets table #{__MODULE__}")

    try do
      :ets.new(__MODULE__, [:named_table, :public])
    rescue
      ArgumentError ->
        :ets.delete(__MODULE__)
        :ets.new(__MODULE__, [:named_table, :public])
    end

    try do
      pid
      |> Process.register(:parent)
    rescue
      ArgumentError ->
        Process.unregister(:parent)

        pid
        |> Process.register(:parent)
    end
  end
end
