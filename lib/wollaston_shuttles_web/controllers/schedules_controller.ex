defmodule WollastonShuttlesWeb.SchedulesController do
  use WollastonShuttlesWeb, :controller

  defmodule State do
    @url "https://dev.api.mbtace.com/schedules?" <>
                                    "filter[route]=Shuttle005&" <>
                                    "include=route,stop&" <>
                                    "filter[date]=2018-01-08&" <>
                                    "api_key=" <> System.get_env("V3_API_KEY")

    use GenServer
    def init(_) do
      @url
      |> IO.inspect(label: "schedules url")
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

    def handle_call(:get_schedules, _from, %{data: [schedule | _]} = state) do
      IO.inspect(schedule, label: "schedule")
      {:reply, state, state}
    end
  end

  def init(func) do
    pid = case GenServer.start_link(__MODULE__.State, [], name: __MODULE__.State) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
    IO.inspect(pid, label: "SchedulesController.State pid")
    # func
    # |> super()
    # |> IO.inspect(label: "super init")
    {func, pid}
  end

  def call(conn, {:index, pid}) do
    json conn, GenServer.call(pid, :get_schedules)
  end
end
