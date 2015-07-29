defmodule SampleApp.UserController do
  use SampleApp.Web, :controller

  plug SampleApp.Plugs.CheckAuthentication
  plug :signed_in_user? when action in [:index, :show, :edit, :update, :delete]
  plug :correct_user? when action in [:show, :edit, :update, :delete]
  plug :action

  def index(conn, params) do
    if !SampleApp.User.is_nil_page?(params) && !SampleApp.User.is_minus_page_number?(params) do
      page = SampleApp.User.paginate(params)
    end

    if page do
      render(conn, "index.html",
             users: page.entries,
             current_page: page.page_number,
             total_pages: page.total_pages,
             page_list: Range.new(1, page.total_pages))
    else
      conn
      |> put_flash(:error, "Invalid page number!!")
      |> redirect(to: static_pages_path(conn, :home))
    end
  end

  def new(conn, _params) do
    changeset = SampleApp.User.changeset(%SampleApp.User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    changeset = SampleApp.User.changeset(%SampleApp.User{}, user_params)

    if changeset.valid? do
      Repo.insert(changeset)

      user = SampleApp.User.find_user_from_email(user_params["email"])

      conn
      |> put_flash(:info, "User registration successfully!!")
      |> put_session(:user_id, user.id)
      |> redirect(to: static_pages_path(conn, :home))
    else
      render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(SampleApp.User, id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Repo.get(SampleApp.User, id)
    user = Map.put(user, :password, SampleApp.User.decrypt(user.password_digest))
    changeset = SampleApp.User.changeset(user)

    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Repo.get(SampleApp.User, id)
    changeset = SampleApp.User.changeset(user, user_params)

    if changeset.valid? do
      Repo.update(changeset)

      conn
      |> put_flash(:info, "User updated successfully!!")
      |> redirect(to: user_path(conn, :show, id))
    else
      conn
      |> put_flash(:error, "UserProfile updated is failed!! name or email or password is incorrect.")
      |> redirect(to: user_path(conn, :edit, id))
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Repo.get(SampleApp.User, id)
    from(m in SampleApp.Micropost, where: m.user_id == ^user.id) |> Repo.delete_all
    Repo.delete(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: static_pages_path(conn, :home))
  end

  defp signed_in_user?(conn, _) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:info, "Please sign-in.")
      |> redirect(to: session_path(conn, :new))
      |> halt
    end
  end

  defp correct_user?(conn, _) do
    user = Repo.get(SampleApp.User, String.to_integer(conn.params["id"]))

    if current_user?(conn, user) do
      conn
    else
      conn
      |> put_flash(:info, "Please sign-in.")
      |> redirect(to: session_path(conn, :new))
      |> halt
    end
  end

  defp current_user?(conn, user) do
    user == conn.assigns[:current_user]
  end
end