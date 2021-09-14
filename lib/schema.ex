defmodule ExSni.Schema do
  use ExDBus.Schema

  node do
    import from(ExDBus.Interfaces)

    node "/MenuBar" do
      import from(ExDBus.Interfaces)
      import from(ExSni.Schema.MenuBar)
    end

    node "/StatusNotifierItem" do
      import from(ExDBus.Interfaces)
      import from(ExSni.Schema.StatusNotifierItem)
    end
  end
end
