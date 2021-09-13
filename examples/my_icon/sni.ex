defmodule MyIcon do
  alias ExSni.Icon
  alias ExSni.Icon.{Info, Tooltip}
  alias ExSni.Menu
  alias ExSni.Menu.Item

  def start() do
    {icon, menu} = setup()

    ExSni.start_link(
      name: "org.example.MyIcon",
      menu: menu,
      icon: icon
    )
  end

  def set_icon(sni_pid) do
    {:ok, icon} = ExSni.get_icon(sni_pid)
    icon_info = %{icon.icon | name: "document-open"}
    icon = %{icon | icon: icon_info}
    ExSni.set_icon(sni_pid, icon)

    {:ok, service_pid} = ExSni.get_service_pid(sni_pid)

    ExDBus.Service.send_signal(
      service_pid,
      "/StatusNotifierItem",
      "org.kde.StatusNotifierItem",
      "NewIcon"
    )
  end

  def setup() do
    menu = %Menu{
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

    icon = %Icon{
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

    {icon, menu}
  end
end
