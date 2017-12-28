defmodule WollastonShuttlesWeb.VehiclesController do
  use WollastonShuttlesWeb, :controller

  defmodule State do
    use GenServer
    @assets_path File.cwd!()
                 |> Path.join("assets")
                 |> IO.inspect(label: "assets path")

    @js_path :wollaston_shuttles
             |> Application.app_dir("priv")
             |> Path.join("decode_polylines.js")

    @url "https://dev.api.mbtace.com/vehicles?" <>
                                    "filter[route]=Red&" <>
                                    "include=route,trip,stop&" <>
                                    "api_key=" <> System.get_env("V3_API_KEY")


    def init(_) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get("https://dev.api.mbtace.com/shapes?filter[route]=Shuttle005&filter[date]=2018-01-08")
      {:ok, %{data: vehicles}} = Poison.decode(body, keys: :atoms)
      {:ok, Enum.map(vehicles, & %{&1.attributes | polyline: decode_polyline(&1.attributes.polyline)})}
      |> IO.inspect()
    end

    def handle_call(:get_vehicles, _from, state) do
      @url
      |> IO.inspect(label: "vehicles url")
      |> HTTPoison.get()
      |> handle_vehicle_response(state)
    end

    def handle_info(:ok, state) do
      {:noreply, state}
    end

    defp handle_vehicle_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}, state) do
      decode_polyline("")
      {:reply, Poison.decode!(body, keys: :atoms), state}
    end

    defp decode_polyline(polyline) do
      {%IO.Stream{}, 0} = System.cmd("node", [@js_path, polyline], cd: @assets_path, into: IO.stream(:stdio, :line))
      :stdio
      |> IO.read(:line)
      |> Enum.map(&clean_coord/1)
      |> IO.inspect(label: "stream", limit: :infinity)
    end

    defp clean_coord("[ [ 42" <> rest) do
      "[ 42"
      |> Kernel.<>(rest)
      |> clean_coord()
    end
    defp clean_coord("[ 42" <> rest) do
      "42"
      |> Kernel.<>(rest)
      |> String.split("]")
      |> List.first()
      |> String.trim()
      |> String.split(",")
      |> Enum.map(& &1 |> String.trim() |> String.to_float())
    end
  end

  def init(func) do
    pid = case GenServer.start_link(__MODULE__.State, [], name: __MODULE__.State) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
    {func, pid}
  end

  def call(conn, {:index, pid}) do
    json conn, GenServer.call(pid, :get_vehicles)
  end
end
