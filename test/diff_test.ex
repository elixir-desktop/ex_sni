defmodule ExSni.MenuDiffTest do
  use ExUnit.Case
  alias ExSni.Menu.Item
  alias ExSni.MenuDiff

  @old_menu """
  <root id="0" uuid="af245ccd-3eaf-4909-b8b6-2a7d1985450b" uid="" enabled="true" visible="true" label="" checked="false">
    <item id="1" uuid="a4a47b70-eb07-424f-ab84-bdc712dce1ba" uid="" type="standard" enabled="true" visible="true" label="Open" checked="false"/>
    <item id="2" uuid="81633cf4-233f-41a4-826f-daf2197aeea2" uid="" type="checkbox" enabled="true" visible="true" label="Pause Network" checked="false"/>
    <item id="3" uuid="b09cb7f5-9fb0-45ed-8a2b-8402e7a16ad6" uid="" type="standard" enabled="false" visible="true" label="No Activity" checked="false"/>
    <item id="4" uuid="928ec29a-2d7f-40ae-9c5b-b7c9696f9a0f" uid="" type="standard" enabled="true" visible="true" label="Quit" checked="false"/>
    <item id="5" uuid="df1323b5-0ed0-4979-a758-36d3e939a363" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <menu id="6" uuid="94f22c24-6e2d-45d6-a0c3-9d2673d92e62" uid="" enabled="true" visible="true" label="DevTools - 10002000" checked="false">
      <item id="7" uuid="d255e376-53bc-480f-a548-7372dd0b481d" uid="" type="standard" enabled="true" visible="true" label="Check for Update" checked="false"/>
      <menu id="8" uuid="8cf0a39c-724d-4bbc-b11f-df3b5e439792" uid="" enabled="true" visible="true" label="View" checked="false">
        <item id="9" uuid="d40511f3-1afb-430a-a247-c8b542867fda" uid="" type="standard" enabled="true" visible="true" label="Open Browser" checked="false"/>
        <item id="10" uuid="7d8bc8c7-5440-4749-a8c1-8188bc2c2ab6" uid="" type="standard" enabled="true" visible="true" label="Show Default Layout" checked="false"/>
        <item id="11" uuid="330403f4-a28a-46f1-a755-3aada9b59198" uid="" type="standard" enabled="true" visible="true" label="Show Android Layout" checked="false"/>
        <item id="12" uuid="1b16c94a-f05c-4a43-8957-8e05ee96d3c3" uid="" type="standard" enabled="true" visible="true" label="Show iOS Layout" checked="false"/>
      </menu>
      <item id="13" uuid="efcdf7d7-3757-4a0f-adaf-b84faa25312b" uid="" type="standard" enabled="true" visible="true" label="Observer" checked="false"/>
      <item id="14" uuid="3f571beb-13d3-4bdf-a0f9-c0706793333d" uid="" type="standard" enabled="true" visible="true" label="Login" checked="false"/>
      <item id="15" uuid="9f51c7bf-9bbc-4b15-add3-921a25145523" uid="" type="standard" enabled="true" visible="true" label="Logout" checked="false"/>
      <item id="16" uuid="0f2f28ef-98de-44e2-87e9-acef961558e7" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="17" uuid="bb3d172a-bda3-4834-9276-0a0e337a2f95" uid="" type="standard" enabled="true" visible="true" label="Restart" checked="false"/>
    </menu>
    <item id="18" uuid="372c06d9-2e98-4f24-ad4f-3f88e8bb95b9" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <item id="19" uuid="8fef8fca-35dd-41f6-a71d-c3a5f5ecd1ca" uid="" type="standard" enabled="true" visible="true" label="Zones" checked="false"/>
    <menu id="20" uuid="683aaa93-2788-48a7-bc23-a8328b8ca634" uid="" enabled="true" visible="true" label="   10002000&apos;s zone" checked="false">
      <item id="21" uuid="be736f4a-471d-4724-9363-29a459febe0c" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="22" uuid="952d7997-5381-4b03-9a8f-5cb656d686fb" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="23" uuid="7dfeb88b-f59d-4721-80c6-8a587b62bf95" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="24" uuid="5a4b76da-2c94-4804-b053-ec8084e125a7" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="25" uuid="aa67ad1e-bcba-45ef-a80e-c76cb5cec1cd" uid="" type="standard" enabled="true" visible="true" label="38.68kb, 2 Files" checked="false"/>
      <item id="26" uuid="4dbc1970-5467-44dd-9506-c7a55c767bdd" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="27" uuid="87fb2b86-3d5d-4e84-b053-9408c9744de4" uid="" type="standard" enabled="true" visible="true" label="Updated i4d18u02asy6qq69 2d ago" checked="false"/>
      <item id="28" uuid="866b40e9-200f-4727-b53d-8c6e3cdb87a0" uid="" type="standard" enabled="false" visible="true" label="Deleted kqchvyjxi1yw70xc 2d ago" checked="false"/>
      <item id="29" uuid="98091b81-5bd2-445a-9642-1845828b2f8b" uid="" type="standard" enabled="false" visible="true" label="Deleted wf88k4px4jstq5q1 2d ago" checked="false"/>
      <item id="30" uuid="3aa61f1e-5ed8-41c2-88eb-6d6226a9c783" uid="" type="standard" enabled="true" visible="true" label="Updated image(2).png 2d ago" checked="false"/>
    </menu>
    <menu id="31" uuid="ece98a90-09c0-48dc-ac9f-2cbea468e482" uid="" enabled="true" visible="true" label="   10002001" checked="false">
      <item id="32" uuid="65af4b03-a6a8-4ccf-934e-e010c93cb9d6" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="33" uuid="7fa15f54-2bc5-4d03-a601-337811c74fe2" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="34" uuid="c933bbf5-4f5a-4f8c-9412-0b8f8d3e00e2" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="35" uuid="172712d4-09b1-4ee1-9766-d33550712fb1" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="36" uuid="c1f1c936-f965-451e-aa8a-5f56c7d28d1d" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
    <menu id="37" uuid="fcd8c780-98a4-4196-8718-518b08c92619" uid="" enabled="true" visible="true" label="   First" checked="false">
      <item id="38" uuid="2cd74973-5f3b-4fd9-af4b-0b96809dc962" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="39" uuid="e7fbe885-b607-4c20-aaa8-ccc4f9df1135" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="40" uuid="0e30403d-8592-45fc-9239-69dbd5417ad7" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="41" uuid="0c785832-d68c-4611-864b-59c9e35a3e03" uid="" type="standard" enabled="true" visible="true" label="3 of 10 Online" checked="false"/>
      <item id="42" uuid="ce8eb8d2-392c-4630-9007-93d92be23561" uid="" type="standard" enabled="true" visible="true" label="1.29gb, 79 Files" checked="false"/>
      <item id="43" uuid="38780496-a250-4d37-b31d-8d03dea07889" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="44" uuid="b403d3f2-3c28-4903-b5ab-4021cb660c17" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.5-win32... 48d ago" checked="false"/>
      <item id="45" uuid="eacad5d9-86a4-4be6-a5e4-09f7c8e3161f" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.0.1-win32... 163d ago" checked="false"/>
      <item id="46" uuid="ef80251a-4687-4b5d-96d7-ae7d2bf0fe0e" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.1-win32... 168d ago" checked="false"/>
      <item id="47" uuid="3bd19d46-b2fa-4bbe-b6b8-714fe814af20" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.3.5.dmg 2d ago" checked="false"/>
      <item id="48" uuid="38f4d101-49d4-4068-8e8a-96f989b885cb" uid="" type="standard" enabled="true" visible="true" label="Downloaded nightly_debug.zip 2d ago" checked="false"/>
    </menu>
    <menu id="49" uuid="1785dd6d-141a-4ea2-a2cf-37e61c2a8014" uid="" enabled="true" visible="true" label="   Mikesnewzone2" checked="false">
      <item id="50" uuid="4c795379-d80e-4e90-80f4-f963c3fcafea" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="51" uuid="1622028c-b702-4849-88e3-8e838890c1f4" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="52" uuid="93946707-cf87-4d0c-935f-8bf55055b69e" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="53" uuid="e719ab8e-55f6-4870-a924-c90435af4314" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="54" uuid="6dea323b-c04a-4e2e-a4ca-96f1da84b2eb" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
  </root>
  """

  @new_menu """
  <root id="0" uuid="12b4c399-d3b8-4eab-90cd-a0a7ebfb8953" uid="" enabled="true" visible="true" label="" checked="false">
    <item id="0" uuid="b8062e81-f88a-4110-b628-8ffaf7d74c52" uid="" type="standard" enabled="true" visible="true" label="Open" checked="false"/>
    <item id="0" uuid="f34a673b-bec6-433c-b424-8269afbce9fe" uid="" type="checkbox" enabled="true" visible="true" label="Pause Network" checked="false"/>
    <item id="0" uuid="53aaff62-2821-4539-abf1-ef78e2c7df19" uid="" type="standard" enabled="false" visible="true" label="No Activity" checked="false"/>
    <item id="0" uuid="4030b76e-aed5-4d90-87a3-11048adc763c" uid="" type="standard" enabled="true" visible="true" label="Quit" checked="false"/>
    <item id="1" uuid="414c1187-da77-47c4-9018-d4332985bb99" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <menu id="0" uuid="f2b35806-743e-4742-ad18-4e1dbc45cb5f" uid="" enabled="true" visible="true" label="DevTools - 10002000" checked="false">
      <item id="0" uuid="bf761e38-11e4-4492-bc7d-d59547d417ee" uid="" type="standard" enabled="true" visible="true" label="Check for Update" checked="false"/>
      <menu id="0" uuid="17e68c4f-3bcd-4e76-b559-7b134e072e48" uid="" enabled="true" visible="true" label="View" checked="false">
        <item id="0" uuid="4b88391f-3811-43d2-8e04-94dd82616bb8" uid="" type="standard" enabled="true" visible="true" label="Open Browser" checked="false"/>
        <item id="0" uuid="39e40638-ef74-4b12-adf1-fad9173f8ff1" uid="" type="standard" enabled="true" visible="true" label="Show Default Layout" checked="false"/>
        <item id="0" uuid="c3c8b494-8177-438e-b0dd-2c33597792a9" uid="" type="standard" enabled="true" visible="true" label="Show Android Layout" checked="false"/>
        <item id="0" uuid="a30115d1-5d7c-4397-a7d0-d50ba300f658" uid="" type="standard" enabled="true" visible="true" label="Show iOS Layout" checked="false"/>
      </menu>
      <item id="0" uuid="49c15936-0a30-4fca-b4cb-d8e5351f3035" uid="" type="standard" enabled="true" visible="true" label="Observer" checked="false"/>
      <item id="0" uuid="11b825ae-f0b9-4281-bb8b-35631a6b8345" uid="" type="standard" enabled="true" visible="true" label="Login" checked="false"/>
      <item id="0" uuid="91d1e216-8c64-48fe-9c4e-10036b0c49bc" uid="" type="standard" enabled="true" visible="true" label="Logout" checked="false"/>
      <item id="1" uuid="cbcad550-2f1c-4e1f-944d-4053830976d2" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uuid="5d505dd1-8f8c-4690-86f7-de9432db6346" uid="" type="standard" enabled="true" visible="true" label="Restart" checked="false"/>
    </menu>
    <item id="1" uuid="646b5d12-14c9-4399-8f6b-089c3b96c7ae" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <item id="0" uuid="1cac10c5-d9ae-4663-8230-d3eec99afd06" uid="" type="standard" enabled="true" visible="true" label="Zones" checked="false"/>
    <menu id="0" uuid="64da9bf4-3212-40c1-8899-3d7308f4f940" uid="" enabled="true" visible="true" label="   10002000&apos;s zone" checked="false">
      <item id="0" uuid="eed87c90-9a11-4222-985e-fd37b9b1f3c7" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="0" uuid="f11fcb4c-2e5f-46cc-b756-7b3c09cb0e43" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="1" uuid="f71445d0-140f-499f-8c1c-b522b3f3f87d" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uuid="2da0e225-cbd6-4415-9500-fe8829581cd2" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="0" uuid="d27396d9-5837-45dc-a92d-a2e4a385776c" uid="" type="standard" enabled="true" visible="true" label="38.68kb, 2 Files" checked="false"/>
      <item id="1" uuid="6568ce65-baca-4c19-b801-b634defbfcae" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uuid="bd5a64a3-a2b0-4ae5-bc62-5f3ecbd8d5a0" uid="" type="standard" enabled="true" visible="true" label="Updated i4d18u02asy6qq69 2d ago" checked="false"/>
      <item id="0" uuid="d01881b0-e9db-42d0-a542-e5bd27364c77" uid="" type="standard" enabled="false" visible="true" label="Deleted kqchvyjxi1yw70xc 2d ago" checked="false"/>
      <item id="0" uuid="61c3e243-4199-466b-b787-368774a75922" uid="" type="standard" enabled="false" visible="true" label="Deleted wf88k4px4jstq5q1 2d ago" checked="false"/>
      <item id="0" uuid="b0c6c7bc-b144-41f5-a3a9-2b28aa33809f" uid="" type="standard" enabled="true" visible="true" label="Updated image(2).png 2d ago" checked="false"/>
    </menu>
    <menu id="0" uuid="0edeb04b-c10f-4cb7-946c-acda1d73396d" uid="" enabled="true" visible="true" label="   10002001" checked="false">
      <item id="0" uuid="9bcd3fc0-c8b0-44a9-a565-f2a2fbe612ef" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="0" uuid="89cd95c8-1828-45a6-b305-bbbad03858f7" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="1" uuid="08530d49-2e86-4c44-b8f3-732be1a3ec68" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uuid="c7e860a7-d080-462d-852e-0b5423cf1166" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="0" uuid="8a85fc0b-8e82-474f-a549-97be09135743" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
    <menu id="0" uuid="89b127c9-4e14-4df5-aebe-99bdb4b2153e" uid="" enabled="true" visible="true" label="   First" checked="false">
      <item id="0" uuid="1dd838f3-2650-4ec3-b11e-8012c0b28c01" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="0" uuid="321fbcbb-3a74-40df-b6b9-a97567a2c0d0" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="1" uuid="89c4e171-7398-42e9-bdd2-7994e433c370" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uuid="1f5020a0-94e4-43ea-b871-8b7c209bd105" uid="" type="standard" enabled="true" visible="true" label="3 of 10 Online" checked="false"/>
      <item id="0" uuid="143fc175-c9ba-44d1-a28a-ede30c0c26f7" uid="" type="standard" enabled="true" visible="true" label="1.29gb, 79 Files" checked="false"/>
      <item id="1" uuid="554b785e-8598-44c9-9877-e26c36693cf0" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uuid="d878eea1-67c2-4ef4-8362-200ed5865d46" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.5-win32... 48d ago" checked="false"/>
      <item id="0" uuid="04b62445-dd52-4534-afd8-b5a634cc3653" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.0.1-win32... 163d ago" checked="false"/>
      <item id="0" uuid="19696f9d-56c3-4265-bfc3-92646e608083" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.1-win32... 168d ago" checked="false"/>
      <item id="0" uuid="69580606-751f-4e46-85f7-3f36e4d022c5" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.3.5.dmg 2d ago" checked="false"/>
      <item id="0" uuid="7bf9df33-4276-4096-8b52-9d8e803bf3c8" uid="" type="standard" enabled="true" visible="true" label="Downloaded nightly_debug.zip 2d ago" checked="false"/>
    </menu>
    <menu id="0" uuid="a1a26acd-da46-47ca-96b1-83c9916a1bab" uid="" enabled="true" visible="true" label="   Mikesnewzone2" checked="false">
      <item id="0" uuid="4ca38b59-3c6a-4b55-abf3-17bcd6815e85" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="0" uuid="11fe674a-3933-47b8-bdce-03c10d181b1b" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="1" uuid="2cc7109e-4a99-45a2-bfc1-5a5f113a4ddc" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uuid="09971ed7-d335-4e5f-a9ab-eaea7ad33513" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="0" uuid="d6d6b790-f88c-494b-8d2c-5fa508a9e5c2" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
    <menu id="0" uuid="1058dc80-e409-4e3b-8923-1567346e674b" uid="" enabled="true" visible="true" label="   Mikesnewzone1" checked="false">
      <item id="0" uuid="eb7943a0-c7c4-483b-acbb-6936c07790c5" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="0" uuid="537af5b7-9681-4449-a418-f99df0d79d55" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="1" uuid="a6330dee-ac2d-4eb9-a69d-f2df6d2c8a76" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uuid="42099a3c-0a9c-4ed0-8454-00dc75abda86" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="0" uuid="2237dfd7-22cc-4861-a46d-da93a1824587" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
  </root>
  """

  @next_menu """
  <root id="0" uuid="12b4c399-d3b8-4eab-90cd-a0a7ebfb8953" uid="" enabled="true" visible="true" label="" checked="false">
    <item id="1" uuid="b8062e81-f88a-4110-b628-8ffaf7d74c52" uid="" type="standard" enabled="true" visible="true" label="Open" checked="false"/>
    <item id="2" uuid="f34a673b-bec6-433c-b424-8269afbce9fe" uid="" type="checkbox" enabled="true" visible="true" label="Pause Network" checked="false"/>
    <item id="3" uuid="53aaff62-2821-4539-abf1-ef78e2c7df19" uid="" type="standard" enabled="false" visible="true" label="No Activity" checked="false"/>
    <item id="4" uuid="4030b76e-aed5-4d90-87a3-11048adc763c" uid="" type="standard" enabled="true" visible="true" label="Quit" checked="false"/>
    <item id="5" uuid="414c1187-da77-47c4-9018-d4332985bb99" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <menu id="6" uuid="f2b35806-743e-4742-ad18-4e1dbc45cb5f" uid="" enabled="true" visible="true" label="DevTools - 10002000" checked="false">
      <item id="7" uuid="bf761e38-11e4-4492-bc7d-d59547d417ee" uid="" type="standard" enabled="true" visible="true" label="Check for Update" checked="false"/>
      <menu id="8" uuid="17e68c4f-3bcd-4e76-b559-7b134e072e48" uid="" enabled="true" visible="true" label="View" checked="false">
        <item id="9" uuid="4b88391f-3811-43d2-8e04-94dd82616bb8" uid="" type="standard" enabled="true" visible="true" label="Open Browser" checked="false"/>
        <item id="10" uuid="39e40638-ef74-4b12-adf1-fad9173f8ff1" uid="" type="standard" enabled="true" visible="true" label="Show Default Layout" checked="false"/>
        <item id="11" uuid="c3c8b494-8177-438e-b0dd-2c33597792a9" uid="" type="standard" enabled="true" visible="true" label="Show Android Layout" checked="false"/>
        <item id="12" uuid="a30115d1-5d7c-4397-a7d0-d50ba300f658" uid="" type="standard" enabled="true" visible="true" label="Show iOS Layout" checked="false"/>
      </menu>
      <item id="13" uuid="49c15936-0a30-4fca-b4cb-d8e5351f3035" uid="" type="standard" enabled="true" visible="true" label="Observer" checked="false"/>
      <item id="14" uuid="11b825ae-f0b9-4281-bb8b-35631a6b8345" uid="" type="standard" enabled="true" visible="true" label="Login" checked="false"/>
      <item id="15" uuid="91d1e216-8c64-48fe-9c4e-10036b0c49bc" uid="" type="standard" enabled="true" visible="true" label="Logout" checked="false"/>
      <item id="16" uuid="cbcad550-2f1c-4e1f-944d-4053830976d2" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="17" uuid="5d505dd1-8f8c-4690-86f7-de9432db6346" uid="" type="standard" enabled="true" visible="true" label="Restart" checked="false"/>
    </menu>
    <item id="18" uuid="646b5d12-14c9-4399-8f6b-089c3b96c7ae" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <item id="19" uuid="1cac10c5-d9ae-4663-8230-d3eec99afd06" uid="" type="standard" enabled="true" visible="true" label="Zones" checked="false"/>
    <menu id="20" uuid="64da9bf4-3212-40c1-8899-3d7308f4f940" uid="" enabled="true" visible="true" label="   10002000&apos;s zone" checked="false">
      <item id="21" uuid="eed87c90-9a11-4222-985e-fd37b9b1f3c7" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="22" uuid="f11fcb4c-2e5f-46cc-b756-7b3c09cb0e43" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="23" uuid="f71445d0-140f-499f-8c1c-b522b3f3f87d" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="24" uuid="2da0e225-cbd6-4415-9500-fe8829581cd2" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="25" uuid="d27396d9-5837-45dc-a92d-a2e4a385776c" uid="" type="standard" enabled="true" visible="true" label="38.68kb, 2 Files" checked="false"/>
      <item id="26" uuid="6568ce65-baca-4c19-b801-b634defbfcae" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="27" uuid="bd5a64a3-a2b0-4ae5-bc62-5f3ecbd8d5a0" uid="" type="standard" enabled="true" visible="true" label="Updated i4d18u02asy6qq69 2d ago" checked="false"/>
      <item id="28" uuid="d01881b0-e9db-42d0-a542-e5bd27364c77" uid="" type="standard" enabled="false" visible="true" label="Deleted kqchvyjxi1yw70xc 2d ago" checked="false"/>
      <item id="29" uuid="61c3e243-4199-466b-b787-368774a75922" uid="" type="standard" enabled="false" visible="true" label="Deleted wf88k4px4jstq5q1 2d ago" checked="false"/>
      <item id="30" uuid="b0c6c7bc-b144-41f5-a3a9-2b28aa33809f" uid="" type="standard" enabled="true" visible="true" label="Updated image(2).png 2d ago" checked="false"/>
    </menu>
    <menu id="31" uuid="0edeb04b-c10f-4cb7-946c-acda1d73396d" uid="" enabled="true" visible="true" label="   10002001" checked="false">
      <item id="32" uuid="9bcd3fc0-c8b0-44a9-a565-f2a2fbe612ef" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="33" uuid="89cd95c8-1828-45a6-b305-bbbad03858f7" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="34" uuid="08530d49-2e86-4c44-b8f3-732be1a3ec68" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="35" uuid="c7e860a7-d080-462d-852e-0b5423cf1166" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="36" uuid="8a85fc0b-8e82-474f-a549-97be09135743" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
    <menu id="37" uuid="89b127c9-4e14-4df5-aebe-99bdb4b2153e" uid="" enabled="true" visible="true" label="   First" checked="false">
      <item id="38" uuid="1dd838f3-2650-4ec3-b11e-8012c0b28c01" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="39" uuid="321fbcbb-3a74-40df-b6b9-a97567a2c0d0" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="40" uuid="89c4e171-7398-42e9-bdd2-7994e433c370" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="41" uuid="1f5020a0-94e4-43ea-b871-8b7c209bd105" uid="" type="standard" enabled="true" visible="true" label="3 of 10 Online" checked="false"/>
      <item id="42" uuid="143fc175-c9ba-44d1-a28a-ede30c0c26f7" uid="" type="standard" enabled="true" visible="true" label="1.29gb, 79 Files" checked="false"/>
      <item id="43" uuid="554b785e-8598-44c9-9877-e26c36693cf0" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="44" uuid="d878eea1-67c2-4ef4-8362-200ed5865d46" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.5-win32... 48d ago" checked="false"/>
      <item id="45" uuid="04b62445-dd52-4534-afd8-b5a634cc3653" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.0.1-win32... 163d ago" checked="false"/>
      <item id="46" uuid="19696f9d-56c3-4265-bfc3-92646e608083" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.1-win32... 168d ago" checked="false"/>
      <item id="47" uuid="69580606-751f-4e46-85f7-3f36e4d022c5" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.3.5.dmg 2d ago" checked="false"/>
      <item id="48" uuid="7bf9df33-4276-4096-8b52-9d8e803bf3c8" uid="" type="standard" enabled="true" visible="true" label="Downloaded nightly_debug.zip 2d ago" checked="false"/>
    </menu>
    <menu id="49" uuid="a1a26acd-da46-47ca-96b1-83c9916a1bab" uid="" enabled="true" visible="true" label="   Mikesnewzone2" checked="false">
      <item id="50" uuid="4ca38b59-3c6a-4b55-abf3-17bcd6815e85" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="51" uuid="11fe674a-3933-47b8-bdce-03c10d181b1b" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="52" uuid="2cc7109e-4a99-45a2-bfc1-5a5f113a4ddc" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="53" uuid="09971ed7-d335-4e5f-a9ab-eaea7ad33513" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="54" uuid="d6d6b790-f88c-494b-8d2c-5fa508a9e5c2" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
    <menu id="55" uuid="1058dc80-e409-4e3b-8923-1567346e674b" uid="" enabled="true" visible="true" label="   Mikesnewzone1" checked="false">
      <item id="56" uuid="eb7943a0-c7c4-483b-acbb-6936c07790c5" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="57" uuid="537af5b7-9681-4449-a418-f99df0d79d55" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="58" uuid="a6330dee-ac2d-4eb9-a69d-f2df6d2c8a76" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="59" uuid="42099a3c-0a9c-4ed0-8454-00dc75abda86" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="60" uuid="2237dfd7-22cc-4861-a46d-da93a1824587" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
  </root>
  """

  setup do
    old_root = build_root(@old_menu)
    new_root = build_root(@new_menu)
    {:ok, %{old_root: old_root, new_root: new_root}}
  end

  test "something", %{old_root: old_root, new_root: new_root} do
    {layout, updates, root} = MenuDiff.diff(new_root, old_root)

    assert layout == 0
    assert updates == []
    assert String.replace(@old_menu, ~r/\n\s*/, "") == ExSni.XML.Builder.encode!(old_root)
    assert String.replace(@new_menu, ~r/\n\s*/, "") == ExSni.XML.Builder.encode!(new_root)
    assert String.replace(@next_menu, ~r/\n\s*/, "") == ExSni.XML.Builder.encode!(root)
  end

  defp build_root(source) do
    case Saxy.SimpleForm.parse_string(source) do
      {:ok, {"root", attrs, children}} ->
        uuid_value =
          case Enum.find(attrs, fn {key, _} -> key == "uuid" end) do
            {_, value} -> value
            _ -> ""
          end

        children = build_nodes(children) |> Enum.reject(fn node -> node == nil end)
        %Item{type: :root, uuid: uuid_value, children: children}

      _ ->
        nil
    end
  end

  defp build_nodes([]) do
    []
  end

  defp build_nodes([child | children]) do
    [build_node(child) | build_nodes(children)]
  end

  defp build_node({"menu", attrs, children}) do
    children = build_nodes(children) |> Enum.reject(fn node -> node == nil end)
    node = %Item{type: :menu, children: children}

    Enum.reduce(attrs, node, fn {name, value}, node ->
      set_attr(node, name, value)
    end)
  end

  defp build_node({"item", attrs, children}) do
    children = build_nodes(children) |> Enum.reject(fn node -> node == nil end)
    {_, value} = Enum.find(attrs, fn {key, _} -> key == "type" end)
    node = %Item{type: String.to_atom(value), children: children}

    Enum.reduce(attrs, node, fn {name, value}, node ->
      set_attr(node, name, value)
    end)
  end

  defp build_node(_) do
    nil
  end

  defp set_attr(node, "type", value) do
    Map.put(node, :type, String.to_atom(value))
  end

  defp set_attr(node, name, "true") do
    Map.put(node, String.to_atom(name), true)
  end

  defp set_attr(node, name, "false") do
    Map.put(node, String.to_atom(name), false)
  end

  defp set_attr(node, "id", value) do
    {id_value, _} = Integer.parse(value)
    Map.put(node, :id, id_value)
  end

  defp set_attr(node, name, value) when name in ["label", "uuid"] do
    Map.put(node, String.to_atom(name), value)
  end

  defp set_attr(node, _, _) do
    node
  end
end
