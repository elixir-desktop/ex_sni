defmodule MyIcon do
  @moduledoc """
  ```
    {:ok, pid} = MyIcon.start()
    # Change the icon
    MyIcon.change_icon(pid)
  ```
  """
  alias ExSni.Icon
  alias ExSni.Icon.{Info, Tooltip}
  alias ExSni.Menu
  alias ExSni.Menu.Item

  def start() do
    with {:ok, pid} <-
           ExSni.start_link(
             name: "org.example.MyIcon",
             menu: create_menu(),
             icon: create_icon()
           ),
         :ok <- ExSni.register_icon(pid) do
      {:ok, pid}
    end
  end

  def change_icon(sni_pid) do
    {:ok, icon} = ExSni.get_icon(sni_pid)
    icon_info = %{icon.icon | name: "document-open"}
    icon = %{icon | icon: icon_info}
    ExSni.set_icon(sni_pid, icon)

    ExSni.register_icon(sni_pid)
  end

  def create_menu() do
    %Menu{
      root: %Item{
        id: 0,
        children: [
          %Item{
            id: 1,
            label: "File"
          },
          %Item{
            id: 2,
            label: "View"
          },
          %Item{
            id: 3,
            label: "Quit"
          }
        ]
      }
    }
  end

  def create_icon() do
    %Icon{
      category: :application_status,
      id: "1",
      title: "Test_Icon",
      menu: "/MenuBar",
      status: :active,
      icon: %Info{
        name: "applications-development"
      },
      tooltip: %Tooltip{
        name: "applications-development",
        title: "test-tooltip",
        description: "Some tooltip description here"
      }
    }
  end
end
