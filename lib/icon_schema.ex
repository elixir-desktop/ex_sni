defmodule ExSni.IconSchema do
  use ExDBus.Schema

  node do
    import from(ExDBus.Interfaces)

    node "/MenuBar" do
      import from(ExDBus.Interfaces)
      import from(ExSni.Interfaces.MenuBar)
    end

    node "/StatusNotifierItem" do
      import from(ExDBus.Interfaces)
      import from(ExSni.Interfaces.StatusNotifierItem)
    end
  end
end
