with Tropos.Reader;

with Concorde.Handles.Component;

with Concorde.Handles.Hull_Armor;
with Concorde.Handles.Hull_Configuration;

with Concorde.Handles.Bridge;
with Concorde.Handles.Computer;
with Concorde.Handles.Engine;
with Concorde.Handles.Generator;
with Concorde.Handles.Jump_Drive;
with Concorde.Handles.Reinforcement;
with Concorde.Handles.Quarters;
with Concorde.Handles.Sensor;
with Concorde.Handles.Stealth;
with Concorde.Handles.Weapon_Mount;

with Concorde.Handles.Ship_Design;
with Concorde.Handles.Ship_Design_Module;

with Concorde.Handles.Technology;

with Concorde.Db;

package body Concorde.Configure.Ships is

   Basic_Power_Per_Ton : constant := 0.2;

   function Get_Fraction
     (Config : Tropos.Configuration;
      Name   : String)
      return Real
   is (Real (Long_Float'(Config.Get (Name, 1.0))));

   function Get_Value
     (Config : Tropos.Configuration;
      Name   : String)
      return Real
   is (Real (Long_Float'(Config.Get (Name, 0.0))));

   procedure Configure_Design
     (Config : Tropos.Configuration);

   procedure Configure_Armor
     (Config : Tropos.Configuration);

   procedure Configure_Bridge
     (Config : Tropos.Configuration);

   procedure Configure_Computer
     (Config : Tropos.Configuration);

   procedure Configure_Generator
     (Config : Tropos.Configuration);

   procedure Configure_Hull
     (Config : Tropos.Configuration);

   procedure Configure_Engine
     (Config : Tropos.Configuration);

   procedure Configure_Jump_Drive
     (Config : Tropos.Configuration);

   procedure Configure_Quarters
     (Config : Tropos.Configuration);

   procedure Configure_Sensor
     (Config : Tropos.Configuration);

   procedure Configure_Weapon_Mount
     (Config : Tropos.Configuration);

   ---------------------
   -- Configure_Armor --
   ---------------------

   procedure Configure_Armor
     (Config : Tropos.Configuration)
   is
      function Get (Name : String) return Real
      is (Get_Fraction (Config, Name));

   begin
      Concorde.Handles.Hull_Armor.Create
        (Tag           => Config.Config_Name,
         Enabled_By    => Concorde.Handles.Technology.Empty_Handle,
         Tonnage       => Get ("tonnage"),
         Cost_Fraction => Get ("cost"),
         Max_Armor     => Config.Get ("max_armor"));
   end Configure_Armor;

   ----------------------
   -- Configure_Bridge --
   ----------------------

   procedure Configure_Bridge
     (Config : Tropos.Configuration)
   is
      function Get (Name : String) return Real
      is (Get_Value (Config, Name));

      Tonnage : constant Non_Negative_Real := Get ("tonnage");
      Ship_Tons : constant Tropos.Configuration :=
                    Config.Child ("ship_tonnage");
   begin
      Concorde.Handles.Bridge.Create
        (Minimum_Tonnage => Tonnage,
         Power_Per_Ton   => 0.0,
         Price_Per_Ton   => Concorde.Money.To_Price (Get ("price") / Tonnage),
         Tag             => Config.Config_Name,
         Enabled_By      => Concorde.Handles.Technology.Empty_Handle,
         Tonnage         => Tonnage,
         Ship_Tons_Low   => Real (Long_Float'(Ship_Tons.Get (1))),
         Ship_Tons_High  => Real (Long_Float'(Ship_Tons.Get (2))));
   end Configure_Bridge;

   ------------------------
   -- Configure_Computer --
   ------------------------

   procedure Configure_Computer
     (Config : Tropos.Configuration)
   is
      function Get (Name : String) return Real
      is (Get_Value (Config, Name));
   begin
      Concorde.Handles.Computer.Create
        (Minimum_Tonnage => 1.0,
         Power_Per_Ton   => 0.0,
         Price_Per_Ton   => Concorde.Money.To_Price (Get ("price")),
         Tag             => Config.Config_Name,
         Enabled_By      => Concorde.Handles.Technology.Empty_Handle,
         Capacity        => Config.Get ("capacity"));
   end Configure_Computer;

   ----------------------
   -- Configure_Design --
   ----------------------

   procedure Configure_Design
     (Config : Tropos.Configuration)
   is

      function Get (Name : String) return Real
      is (Get_Value (Config, Name));

      Hull                      : constant Concorde.Handles.Hull_Configuration
        .Hull_Configuration_Class :=
               Concorde.Handles.Hull_Configuration.Get_By_Tag
                 (Config.Get ("hull", "standard"));
      Armor : constant Concorde.Handles.Hull_Armor.Hull_Armor_Class :=
                Concorde.Handles.Hull_Armor.Get_By_Tag
                  (Config.Get ("armor", ""));

      Tonnage : constant Non_Negative_Real := Get ("tonnage");
      Hull_Points : constant Non_Negative_Real :=
                      Tonnage / 2.5
                        + (if Tonnage > 25_000.0
                           then (Tonnage - 25_000.0) / 4.0 else 0.0)
                        + (if Tonnage > 100_000.0
                           then (Tonnage - 100_000.0) / 2.0 else 0.0);

      Fuel_Tank : constant Non_Negative_Real :=
                    Get_Value (Config, "fuel_tank");

      Firm_Points : constant Natural :=
                      (if Tonnage < 35.0 then 1
                       elsif Tonnage < 70.0 then 2
                       elsif Tonnage < 100.0 then 3
                       else 0);
      Hard_Points : constant Natural :=
                      Natural (Real'Truncation (Tonnage / 100.0));

      Design : constant Concorde.Handles.Ship_Design.Ship_Design_Class :=
                 Concorde.Handles.Ship_Design.Create
                   (Name               =>
                                 Config.Get ("name", Config.Config_Name),
                    Hull_Configuration => Hull,
                    Hull_Armor         => Armor,
                    Stealth            =>
                      Concorde.Handles.Stealth.Empty_Handle,
                    Reinforcement      =>
                      Concorde.Handles.Reinforcement.Empty_Handle,
                    Tonnage            => Tonnage,
                    Hull_Points        => Hull_Points,
                    Fuel_Tank          => Fuel_Tank,
                    Cargo_Space        => 0.0,
                    Basic_Power        => 0.0,
                    Engine_Power       => 0.0,
                    Jump_Power         => 0.0,
                    Firmpoints         => Firm_Points,
                    Hardpoints         => Hard_Points);

      procedure Configure_Bridge_Design
        (Config : Tropos.Configuration);

      procedure Configure_Computer_Design
        (Config : Tropos.Configuration);

      procedure Configure_Engine_Design
        (Engine : Concorde.Handles.Engine.Engine_Class);

      procedure Configure_Generator_Design
        (Gen_Config : Tropos.Configuration);

      procedure Configure_Jump_Design
        (Jump_Drive : Concorde.Handles.Jump_Drive.Jump_Drive_Class);

      procedure Configure_Quarters_Design
        (Config : Tropos.Configuration);

      procedure Configure_Sensor_Design
        (Config : Tropos.Configuration);

      procedure Configure_Weapon_Mount_Design
        (Config : Tropos.Configuration);

      -----------------------------
      -- Configure_Bridge_Design --
      -----------------------------

      procedure Configure_Bridge_Design
        (Config : Tropos.Configuration)
      is
         Handle : constant Concorde.Handles.Bridge.Bridge_Handle :=
                    Concorde.Handles.Bridge.Get_By_Tag
                      (Config.Get ("type"));
      begin
         Concorde.Handles.Ship_Design_Module.Create
           (Ship_Design => Design,
            Component   => Handle,
            Tonnage     => Handle.Tonnage,
            Concealed   => False);
      end Configure_Bridge_Design;

      -------------------------------
      -- Configure_Computer_Design --
      -------------------------------

      procedure Configure_Computer_Design
        (Config : Tropos.Configuration)
      is
         Handle : constant Concorde.Handles.Computer.Computer_Handle :=
                    Concorde.Handles.Computer.Get_By_Tag
                      (Config.Get ("type"));
      begin
         Concorde.Handles.Ship_Design_Module.Create
           (Ship_Design => Design,
            Component   => Handle,
            Tonnage     => 1.0,
            Concealed   => False);
      end Configure_Computer_Design;

      -----------------------------
      -- Configure_Engine_Design --
      -----------------------------

      procedure Configure_Engine_Design
        (Engine : Concorde.Handles.Engine.Engine_Class)
      is
      begin
         Concorde.Handles.Ship_Design_Module.Create
           (Ship_Design => Design,
            Component   => Engine,
            Tonnage     =>
              Non_Negative_Real'Max
                (Tonnage * Engine.Hull_Fraction,
                 Engine.Minimum_Tonnage),
            Concealed   => False);
      end Configure_Engine_Design;

      --------------------------------
      -- Configure_Generator_Design --
      --------------------------------

      procedure Configure_Generator_Design
        (Gen_Config : Tropos.Configuration)
      is
         Handle : constant Concorde.Handles.Generator.Generator_Handle :=
                    Concorde.Handles.Generator.Get_By_Tag
                      (Gen_Config.Get ("type"));
      begin
         pragma Assert (Handle.Has_Element,
                        "no such generator: "
                        & Gen_Config.Get ("type"));
         Concorde.Handles.Ship_Design_Module.Create
           (Ship_Design => Design,
            Component   => Handle,
            Tonnage     => Get_Value (Gen_Config, "tonnage"),
            Concealed   => False);
      end Configure_Generator_Design;

      ---------------------------
      -- Configure_Jump_Design --
      ---------------------------

      procedure Configure_Jump_Design
        (Jump_Drive : Concorde.Handles.Jump_Drive.Jump_Drive_Class)
      is
      begin
         Concorde.Handles.Ship_Design_Module.Create
           (Ship_Design => Design,
            Component   => Jump_Drive,
            Tonnage     =>
              Non_Negative_Real'Max
                (Tonnage * Jump_Drive.Hull_Fraction,
                 Jump_Drive.Minimum_Tonnage),
            Concealed   => False);
      end Configure_Jump_Design;

      -------------------------------
      -- Configure_Quarters_Design --
      -------------------------------

      procedure Configure_Quarters_Design
        (Config : Tropos.Configuration)
      is
         Handle : constant Concorde.Handles.Quarters.Quarters_Handle :=
                    Concorde.Handles.Quarters.Get_By_Tag
                      (Config.Config_Name);
         Count  : constant Positive :=
                    (if Config.Child_Count = 0
                     then 1
                     else Config.Value);
      begin
         for I in 1 .. Count loop
            Concorde.Handles.Ship_Design_Module.Create
              (Ship_Design => Design,
               Component   => Handle,
               Tonnage     => Handle.Tonnage,
               Concealed   => False);
         end loop;
      end Configure_Quarters_Design;

      -----------------------------
      -- Configure_Sensor_Design --
      -----------------------------

      procedure Configure_Sensor_Design
        (Config : Tropos.Configuration)
      is
         Handle : constant Concorde.Handles.Sensor.Sensor_Handle :=
                    Concorde.Handles.Sensor.Get_By_Tag
                      (Config.Get ("type", "basic"));
      begin
         Concorde.Handles.Ship_Design_Module.Create
           (Ship_Design => Design,
            Component   => Handle,
            Tonnage     => Handle.Tonnage,
            Concealed   => False);
      end Configure_Sensor_Design;

      -----------------------------------
      -- Configure_Weapon_Mount_Design --
      -----------------------------------

      procedure Configure_Weapon_Mount_Design
        (Config : Tropos.Configuration)
      is
         Handle : constant Concorde.Handles.Weapon_Mount.Weapon_Mount_Handle :=
                    Concorde.Handles.Weapon_Mount.Get_By_Tag
                      (Config.Config_Name);
      begin
         pragma Assert (Handle.Has_Element);
         Concorde.Handles.Ship_Design_Module.Create
           (Ship_Design => Design,
            Component   => Handle,
            Tonnage     => Handle.Tonnage,
            Concealed   => Config.Get ("concealed"));
      end Configure_Weapon_Mount_Design;

   begin
      Configure_Engine_Design
        (Concorde.Handles.Engine.Get_By_Tag (Config.Get ("engine")));

      if Config.Contains ("jump") then
         Configure_Jump_Design
           (Concorde.Handles.Jump_Drive.Get_By_Tag
              (Config.Get ("jump")));
      end if;

      Configure_Generator_Design (Config.Child ("generator"));
      Configure_Bridge_Design (Config.Child ("bridge"));
      Configure_Computer_Design (Config.Child ("computer"));
      Configure_Sensor_Design (Config.Child ("sensor"));

      for Weapon_Mount_Config of Config.Child ("weapon-mounts") loop
         Configure_Weapon_Mount_Design (Weapon_Mount_Config);
      end loop;

      for Quarters_Config of Config.Child ("quarters") loop
         Configure_Quarters_Design (Quarters_Config);
      end loop;

      declare
         Space        : Non_Negative_Real := Tonnage - Fuel_Tank;
         Basic_Power  : constant Non_Negative_Real :=
                          Tonnage * Basic_Power_Per_Ton;
         Engine_Power : Non_Negative_Real := 0.0;
         Jump_Power   : Non_Negative_Real := 0.0;
      begin
         for Module of
           Concorde.Handles.Ship_Design_Module.Select_By_Ship_Design
             (Design)
         loop
            Space := Space - Module.Tonnage;

            declare
               use Concorde.Db;
            begin
               if Module.Component.Top_Record = R_Engine then
                  declare
                     Engine : constant Concorde.Handles.Engine.Engine_Class :=
                                Concorde.Handles.Engine.Get_From_Component
                                  (Module.Component);
                  begin
                     Engine_Power := Engine_Power
                       + Engine.Power_Per_Ton * Module.Tonnage;
                  end;
               elsif Module.Component.Top_Record = R_Jump_Drive then
                  declare
                     Jump               : constant Concorde.Handles.Jump_Drive
                       .Jump_Drive_Handle :=
                         Concorde.Handles.Jump_Drive.Get_From_Component
                           (Module.Component);
                  begin
                     Jump_Power := Jump_Power
                       + Jump.Power_Per_Ton * Module.Tonnage;
                  end;
               end if;
            end;
         end loop;

         Concorde.Handles.Ship_Design.Update_Ship_Design (Design)
           .Set_Cargo_Space (Space)
           .Set_Basic_Power (Basic_Power)
           .Set_Engine_Power (Engine_Power)
           .Set_Jump_Power (Jump_Power)
           .Done;
      end;
   end Configure_Design;

   ----------------------
   -- Configure_Engine --
   ----------------------

   procedure Configure_Engine
     (Config : Tropos.Configuration)
   is

      function Get (Name : String) return Real
      is (Get_Fraction (Config, Name));

   begin
      Concorde.Handles.Engine.Create
        (Minimum_Tonnage => Get_Value (Config, "minimum_size"),
         Power_Per_Ton   => Get ("power_per_ton"),
         Price_Per_Ton   => Concorde.Money.To_Price (Get ("cost")),
         Tag             => Config.Config_Name,
         Enabled_By      => Concorde.Handles.Technology.Empty_Handle,
         Hull_Fraction   => Get ("hull"),
         Impulse         => Get ("impulse"));
   end Configure_Engine;

   -------------------------
   -- Configure_Generator --
   -------------------------

   procedure Configure_Generator
     (Config : Tropos.Configuration)
   is
      function Get (Name : String) return Real
      is (Get_Value (Config, Name));

   begin
      Concorde.Handles.Generator.Create
        (Minimum_Tonnage => Get_Value (Config, "minimum_size"),
         Fuel_Per_Ton    => Get ("fuel_per_ton_per_day"),
         Price_Per_Ton   => Concorde.Money.To_Price (Get ("price_per_ton")),
         Tag             => Config.Config_Name,
         Enabled_By      => Concorde.Handles.Technology.Empty_Handle,
         Power_Per_Ton   => Get ("power_per_ton"));
   end Configure_Generator;

   --------------------
   -- Configure_Hull --
   --------------------

   procedure Configure_Hull
     (Config : Tropos.Configuration)
   is

      function Get (Name : String) return Real
      is (Get_Fraction (Config, Name));

   begin
      Concorde.Handles.Hull_Configuration.Create
        (Tag           => Config.Config_Name,
         Streamlining  => Get ("streamlining"),
         Hull_Points   => Get ("hull_points"),
         Cost          => Get ("cost"),
         Armor_Tonnage => Get ("armor_tonnage"));
   end Configure_Hull;

   --------------------------
   -- Configure_Jump_Drive --
   --------------------------

   procedure Configure_Jump_Drive
     (Config : Tropos.Configuration)
   is

      function Get (Name : String) return Real
      is (Get_Fraction (Config, Name));

   begin
      Concorde.Handles.Jump_Drive.Create
        (Minimum_Tonnage => Get_Value (Config, "minimum_size"),
         Power_Per_Ton   => Get ("power_per_ton"),
         Price_Per_Ton   => Concorde.Money.To_Price (Get ("cost")),
         Tag             => Config.Config_Name,
         Enabled_By      => Concorde.Handles.Technology.Empty_Handle,
         Hull_Fraction   => Get ("hull"),
         Jump            => Get ("jump"));
   end Configure_Jump_Drive;

   ------------------------
   -- Configure_Quarters --
   ------------------------

   procedure Configure_Quarters
     (Config : Tropos.Configuration)
   is
      function Get (Name : String) return Real
      is (Get_Value (Config, Name));

      Tonnage : constant Non_Negative_Real := Get ("tonnage");
   begin
      Concorde.Handles.Quarters.Create
        (Power_Per_Ton      => Get ("power_per_ton"),
         Minimum_Tonnage    => Tonnage,
         Price_Per_Ton      => Concorde.Money.To_Price (Get ("price_per_ton")),
         Tag                => Config.Config_Name,
         Enabled_By         => Concorde.Handles.Technology.Empty_Handle,
         Tonnage            => Tonnage,
         Comfort_Level      => Config.Get ("comfort"),
         Standard_Occupants => Config.Get ("occupancy"),
         Max_Occupants      => Config.Get ("max_occupancy"));
   end Configure_Quarters;

   ----------------------
   -- Configure_Sensor --
   ----------------------

   procedure Configure_Sensor
     (Config : Tropos.Configuration)
   is
      function Get (Name : String) return Real
      is (Get_Value (Config, Name));

      Tonnage : constant Non_Negative_Real := Get ("tonnage");
   begin
      Concorde.Handles.Sensor.Create
        (Minimum_Tonnage => Get_Value (Config, "minimum_size"),
         Power_Per_Ton   => Get ("power") / Real'Max (Tonnage, 1.0),
         Price_Per_Ton   => Concorde.Money.To_Price (Get ("price")
           / Real'Max (Tonnage, 1.0)),
         Tag             => Config.Config_Name,
         Enabled_By      => Concorde.Handles.Technology.Empty_Handle,
         Tonnage         => Tonnage,
         Modifier        => Config.Get ("modifier"));
   end Configure_Sensor;

   ---------------------
   -- Configure_Ships --
   ---------------------

   procedure Configure_Ships (Scenario_Name : String) is

      procedure Configure
        (Category_Name : String;
         Extension     : String;
         Process       : not null access
           procedure (Config : Tropos.Configuration));

      ---------------
      -- Configure --
      ---------------

      procedure Configure
        (Category_Name : String;
         Extension     : String;
         Process       : not null access
           procedure (Config : Tropos.Configuration))
      is
      begin
         Tropos.Reader.Read_Config
           (Path      =>
              Scenario_File (Scenario_Name, "ships", Category_Name),
            Extension => Extension,
            Configure => Process);
      end Configure;

   begin
      Configure ("hulls", "hull", Configure_Hull'Access);
      Configure ("armor", "armor", Configure_Armor'Access);
      Configure ("engines", "engine", Configure_Engine'Access);
      Configure ("jump-drives", "jump", Configure_Jump_Drive'Access);
      Configure ("generators", "generator", Configure_Generator'Access);
      Configure ("bridges", "bridge", Configure_Bridge'Access);
      Configure ("computers", "computer", Configure_Computer'Access);
      Configure ("quarters", "quarters", Configure_Quarters'Access);
      Configure ("sensors", "sensor", Configure_Sensor'Access);
      Configure ("weapon-mounts", "mount", Configure_Weapon_Mount'Access);

      Configure ("designs", "design", Configure_Design'Access);

   end Configure_Ships;

   ----------------------------
   -- Configure_Weapon_Mount --
   ----------------------------

   procedure Configure_Weapon_Mount
     (Config : Tropos.Configuration)
   is

      function Get (Name : String) return Real
      is (Get_Value (Config, Name));

      function Get (Name : String) return Concorde.Money.Price_Type
      is (Concorde.Money.To_Price (Get (Name)));

      function Get (Name : String) return Concorde.Db.Weapon_Mount_Category
      is (Concorde.Db.Weapon_Mount_Category'Value
          (Config.Get (Name)));

   begin
      Concorde.Handles.Weapon_Mount.Create
        (Tag             => Config.Config_Name,
         Enabled_By      => Concorde.Handles.Technology.Empty_Handle,
         Power_Per_Ton   => Get ("power"),
         Minimum_Tonnage => Get ("tonnage"),
         Price_Per_Ton   => Get ("price"),
         Category        => Get ("category"),
         Fixed           => Config.Get ("fixed"),
         Hardpoints      => Config.Get ("hardpoints"),
         Weapon_Count    => Config.Get ("weapons"),
         Tonnage         => Get ("tonnage"));
   end Configure_Weapon_Mount;

end Concorde.Configure.Ships;
