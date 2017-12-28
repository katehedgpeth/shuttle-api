defmodule WollastonShuttlesWeb.ShapesController do
  use WollastonShuttlesWeb, :controller

  defmodule State do
    use GenServer
    @url "https://dev.api.mbtace.com/shapes?filter[route]=Shuttle005&include=route,stops&api_key=" <> System.get_env("V3_API_KEY")

    def init(_) do
      @url
      |> IO.inspect(label: "shapes url")
      |> HTTPoison.get()
      |> do_init()
    end

    defp do_init({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
      {:ok, Poison.decode!(body, keys: :atoms)}
    end
    defp do_init({:error, %HTTPoison.Error{reason: :timeout}}) do
      IO.inspect("shapes request timed out: retrying")
      init([])
    end

    def handle_call(:get_shapes, _from, state) do
      {:reply, state, state}
    end
  end

  def init(func) do
    pid = case GenServer.start_link(State, [], name: __MODULE__.State) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
    IO.inspect(pid, label: "ShapesController.State pid")
    # super(func)
    {func, pid}
  end

  def call(conn, {:index, pid}) do
    json(conn, GenServer.call(pid, :get_shapes))
  end
end
