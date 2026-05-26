defmodule LetsChat.Chat.Room do
  @moduledoc false
  use Ash.Resource,
    otp_app: :lets_chat,
    domain: LetsChat.Chat,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "rooms"
    repo LetsChat.Repo

    references do
      reference :owner, on_delete: :nothing
    end
  end

  actions do
    defaults []

    read :read do
      primary? true
    end

    read :list do
      prepare build(sort: [inserted_at: :desc])
    end

    read :get_by_slug do
      argument :slug, :string, allow_nil?: false
      get? true
      filter expr(slug == ^arg(:slug))
    end

    create :create do
      primary? true
      accept [:name, :visibility, :owner_session_id]

      change fn changeset, _context ->
        Ash.Changeset.before_action(changeset, fn changeset ->
          name = Ash.Changeset.get_attribute(changeset, :name)
          base_slug = Slug.slugify(name)
          slug = resolve_unique_slug(base_slug)
          Ash.Changeset.force_change_attribute(changeset, :slug, slug)
        end)
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
      constraints min_length: 1
    end

    attribute :slug, :string do
      allow_nil? false
      public? true
      filterable? :simple_equality
    end

    attribute :visibility, :atom do
      allow_nil? false
      public? true
      default :public
      constraints one_of: [:public, :private]
    end

    attribute :owner_session_id, :string do
      allow_nil? true
      public? true
    end

    attribute :inserted_at, AshPostgres.Timestamptz do
      allow_nil? false
      public? true
      writable? false
      default &DateTime.utc_now/0
    end
  end

  relationships do
    belongs_to :owner, LetsChat.Accounts.User do
      source_attribute :owner_user_id
      allow_nil? true
      public? false
    end
  end

  identities do
    identity :unique_slug, [:slug]
  end

  defp resolve_unique_slug(base_slug) do
    if slug_exists?(base_slug), do: find_available_slug(base_slug), else: base_slug
  end

  defp find_available_slug(base_slug) do
    Enum.find_value(2..999, &candidate_slug(base_slug, &1)) || "#{base_slug}-2"
  end

  defp candidate_slug(base_slug, n) do
    candidate = "#{base_slug}-#{n}"
    if !slug_exists?(candidate), do: candidate
  end

  defp slug_exists?(slug) do
    Ash.exists?(
      Ash.Query.filter_input(__MODULE__, %{slug: slug}),
      authorize?: false
    )
  end
end

defimpl LiveVue.Encoder, for: LetsChat.Chat.Room do
  def encode(room, opts) do
    LiveVue.Encoder.encode(
      %{id: room.id, name: room.name, slug: room.slug, inserted_at: room.inserted_at},
      opts
    )
  end
end
