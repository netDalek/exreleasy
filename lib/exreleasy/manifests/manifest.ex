defmodule Exreleasy.Manifests.Manifest do

  alias __MODULE__
  alias Exreleasy.Manifests.App
  alias Exreleasy.Release
  alias Exreleasy.CurrentProject

  defstruct [
    apps: %{},
    deps: %{},
  ]

  @type t :: %__MODULE__{
    apps: %{atom => App.t},
    deps: %{atom => String.t},
  }

  @spec in_release_path() :: Path.t
  def in_release_path() do
    Path.join(Release.dir(), filename())
  end

  @spec filename() :: Path.t
  def filename() do
    "exreleasy.json"
  end

  @spec new(map) :: t
  def new(options) do
    apps = options["apps"] |> Enum.map(fn {k,v} -> {String.to_atom(k), App.new(v)} end) |> Enum.into(%{})
    deps = options["deps"] |> Enum.map(fn {k,v} -> {String.to_atom(k), v} end) |> Enum.into(%{})

    %Manifest{apps: apps, deps: deps}
  end

  @spec digest([atom]) :: {:ok, t} | {:error, term}
  def digest(apps) do
    with {:ok, app_digests} <- digest_apps(apps, %{}),
         {:ok, deps} <- CurrentProject.dependencies_versions() do
      manifest = %Manifest{
        apps: app_digests,
        deps: deps
      }
      {:ok, manifest}
    end
  end

  @spec apps_set(t) :: Set.t
  def apps_set(manifest) do
    manifest.apps |> Map.keys |>  MapSet.new()
  end

  defp digest_apps([], results), do: {:ok, results}
  defp digest_apps([app|other_apps], results) do
    with {:ok, app_manifest} <- App.digest(app),
      do: digest_apps(other_apps, Map.put(results, app, app_manifest))
  end

end
