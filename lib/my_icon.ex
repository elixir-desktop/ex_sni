defmodule MyIcon do
  alias ExSni.Icon
  alias ExSni.Icon.{Info, Tooltip}
  alias ExSni.Menu
  alias ExSni.Menu.Item

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

    {menu, icon}
  end
end
