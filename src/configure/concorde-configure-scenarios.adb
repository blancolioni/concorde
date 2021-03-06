with Ada.Text_IO;

with Tropos.Reader;

with Concorde.Color;
with Concorde.Options;
with Concorde.Paths;

with Concorde.Configure.Careers;
with Concorde.Configure.Commodities;
with Concorde.Configure.Economy;
with Concorde.Configure.Events;
with Concorde.Configure.Galaxies;
with Concorde.Configure.Metrics;
with Concorde.Configure.Policies;
with Concorde.Configure.Pop_Groups;
with Concorde.Configure.Ships;
with Concorde.Configure.Skills;
with Concorde.Configure.Terrain;
with Concorde.Configure.Units;
with Concorde.Configure.Utility;
with Concorde.Configure.Zones;

with Concorde.Configure.Tasks;

with Concorde.Factions.Create;

with Concorde.Handles.Ability;
with Concorde.Handles.Faction;
with Concorde.Handles.Scenario;
with Concorde.Handles.Star_System;
with Concorde.Handles.User;

with Concorde.Db;

package body Concorde.Configure.Scenarios is

   procedure Add_Factions
     (Scenario_Name       : String;
      Faction_Names_File  : String;
      Faction_Colors_File : String;
      Capital_System      : Boolean);

   ------------------
   -- Add_Factions --
   ------------------

   procedure Add_Factions
     (Scenario_Name       : String;
      Faction_Names_File  : String;
      Faction_Colors_File : String;
      Capital_System      : Boolean)
   is
--        Scenario_Config : constant Tropos.Configuration :=
--                            Tropos.Reader.Read_Config
--                              (Scenario_Directory (Scenario_Name)
--                               & "/" & Scenario_Name & ".scenario");
      Name_Config    : constant Tropos.Configuration :=
                         Tropos.Reader.Read_Config
                           (Scenario_File
                              (Scenario_Name, "factions",
                               Faction_Names_File & ".config"));
      Color_Config   : constant Tropos.Configuration :=
                         Tropos.Reader.Read_Config
                           (Scenario_File
                              (Scenario_Name, "factions",
                               Faction_Colors_File & ".config"));
      Faction_Config : Tropos.Configuration :=
                         Tropos.New_Config ("factions");
      Position       : Tropos.Cursor := Color_Config.First;
      First          : Boolean := True;
   begin

      for Config of Name_Config loop
         declare
            New_Config : Tropos.Configuration := Config;
         begin
            New_Config.Add
              ("color", Tropos.Element (Position).Config_Name);
            Faction_Config.Add (New_Config);
            Tropos.Next (Position);
         end;
      end loop;

      for Config of Faction_Config loop

         Ada.Text_IO.Put_Line
           ("new "
            & (if First and then Capital_System then "capital " else "")
            & "faction: " & Config.Get ("name"));

         declare
            Setup_Path : constant String :=
                           Scenario_File
                             (Scenario_Name, "factions",
                              (if Capital_System and then First
                               then "capital.faction"
                               else "default.faction"));
            Faction : constant Concorde.Handles.Faction.Faction_Class :=
                           Concorde.Factions.Create.Create_Faction
                             (User        => Concorde.Handles.User.Create
                                (Login         => Config.Config_Name,
                                 Password      => "",
                                 Administrator => False),
                              Name        => Config.Get ("name"),
                              Adjective   =>
                                Config.Get ("adjective", Config.Get ("name")),
                              Plural_Name =>
                                Config.Get ("plural", Config.Get ("name")),
                              Color       =>
                                Concorde.Color.From_String
                                  (Config.Get ("color", "#ff0000")),
                              Setup       =>
                                Tropos.Reader.Read_Config (Setup_Path));
         begin
            if not Faction.Has_Element then
               Ada.Text_IO.Put_Line
                 (Ada.Text_IO.Standard_Error,
                  "unable to create faction " & Config.Get ("name"));
            end if;
            First := False;
         end;
      end loop;

   end Add_Factions;

   -------------------
   -- Load_Scenario --
   -------------------

   procedure Load_Scenario
     (Scenario_Name  : String;
      Name_Generator : WL.Random.Names.Name_Generator)
   is
      R  : constant Natural := Concorde.Options.Galaxy_Radius;
      RX : constant Natural := Concorde.Options.Galaxy_Radius_X;
      RY : constant Natural := Concorde.Options.Galaxy_Radius_Y;
      RZ : constant Natural := Concorde.Options.Galaxy_Radius_Z;

      Scenario_Config : constant Tropos.Configuration :=
                          Tropos.Reader.Read_Config
                            (Concorde.Paths.Config_File
                               ("scenarios/"
                                & Scenario_Name
                                & "/"
                                & Scenario_Name
                                & ".scenario"));

   begin
      Concorde.Handles.Scenario.Create
        (Scenario_Name, True, Concorde.Handles.Star_System.Empty_Handle);

      Concorde.Configure.Commodities.Configure_Commodities
        (Scenario_Name);

      Concorde.Configure.Utility.Configure_Utility (Scenario_Name);

      Concorde.Configure.Terrain.Configure_Terrain (Scenario_Name);
      Concorde.Configure.Zones.Configure_Zones (Scenario_Name);

      Concorde.Configure.Metrics.Configure_Metrics (Scenario_Name);
      Concorde.Configure.Economy.Configure_Economic_Sectors (Scenario_Name);
      Concorde.Configure.Pop_Groups.Configure_Pop_Groups (Scenario_Name);
      Concorde.Configure.Policies.Configure_Policies (Scenario_Name);
      Concorde.Configure.Metrics.Save_Metrics;

      for Ability_Config of
        Tropos.Reader.Read_Config
          (Scenario_File (Scenario_Name, "individuals", "abilities.txt"))
      loop
         declare
            Category : constant Concorde.Db.Ability_Category :=
                         (if Ability_Config.Contains ("physical")
                          then Concorde.Db.Physical
                          elsif Ability_Config.Contains ("mental")
                          then Concorde.Db.Mental
                          elsif Ability_Config.Contains ("social")
                          then Concorde.Db.Social
                          else (raise Constraint_Error with
                              "cannot categorise: "
                            & Ability_Config.Config_Name));
         begin
            Concorde.Handles.Ability.Create (Ability_Config.Config_Name,
                                        Category);
         end;
      end loop;

      Concorde.Configure.Skills.Configure_Skills (Scenario_Name);
      Concorde.Configure.Events.Configure_Events (Scenario_Name);

      Concorde.Configure.Careers.Configure_Careers (Scenario_Name);

      Concorde.Configure.Ships.Configure_Ships (Scenario_Name);
      Concorde.Configure.Units.Configure_Units (Scenario_Name);

      declare
         Work : Concorde.Configure.Tasks.Configuration_Work;

         task Generate;

         task body Generate is
         begin
            Concorde.Configure.Galaxies.Generate_Galaxy
              (Number_Of_Systems  => Concorde.Options.System_Count,
               Radius_X           => Real (if RX = 0 then R else RX),
               Radius_Y           =>
                 Real (if RY = 0 then (if RX = 0 then R else RX) else RY),
               Radius_Z           =>
                 Real (if RZ = 0 then (if RX = 0 then R else RX) else RZ),
               Create_Coordinates =>
                 Concorde.Configure.Galaxies.Random_Sphere_Distribution'Access,
               Names              => Name_Generator,
               Progress           => Work);
         end Generate;

         Last_Current : Natural := 0;
         Last_Total   : Natural := 0;

         procedure Put_Progress
           (Title   : String;
            Current : Natural;
            Total   : Natural);

         ------------------
         -- Put_Progress --
         ------------------

         procedure Put_Progress
           (Title   : String;
            Current : Natural;
            Total   : Natural)
         is
            New_Line : constant String :=
              Title & ": " & Current'Image & Total'Image;
            Spaces   : constant String (1 .. 72 - New_Line'Length) :=
              (others => ' ');
         begin
            Ada.Text_IO.Put (Character'Val (13) & New_Line & Spaces);
            Ada.Text_IO.Flush;
            Last_Current := Current;
            Last_Total := Total;
         end Put_Progress;

      begin

         while not Work.Finished loop
            delay 0.1;

            declare
               Current, Total : Natural;
            begin
               Work.Get_State (Current, Total);
               if Current /= Last_Current
                 or else Total /= Last_Total
               then
                  Put_Progress (Work.Current_Work_Item, Current, Total);
               end if;
            end;
         end loop;
         Ada.Text_IO.New_Line;
      end;

      Add_Factions
        (Scenario_Name       => Scenario_Name,
         Faction_Names_File  => Scenario_Config.Get ("faction-names"),
         Faction_Colors_File => Scenario_Config.Get ("faction-colors"),
         Capital_System      => Scenario_Config.Get ("capital-system"));
   end Load_Scenario;

end Concorde.Configure.Scenarios;
