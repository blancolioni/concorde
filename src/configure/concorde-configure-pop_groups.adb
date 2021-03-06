with Concorde.Identifiers;

with Concorde.Configure.Metrics;

with Concorde.Handles.Commodity;
with Concorde.Handles.Effect;
with Concorde.Handles.Group_Influence;
with Concorde.Handles.Metric;
with Concorde.Handles.Node;
with Concorde.Handles.Pop_Group;
with Concorde.Handles.Pop_Group_Demand;
with Concorde.Handles.Wealth_Group;

with Concorde.Db;

package body Concorde.Configure.Pop_Groups is

   procedure Configure_Pop_Group
     (Config : Tropos.Configuration);

   procedure Configure_Pop_Group_Metric
     (Pop_Group_Tag : String;
      Metric_Tag    : String;
      Commodity_Tag : String;
      Expression    : String);

   procedure Configure_Influence
     (Config : Tropos.Configuration);

   -------------------------
   -- Configure_Influence --
   -------------------------

   procedure Configure_Influence
     (Config : Tropos.Configuration)
   is
      use Concorde.Handles.Pop_Group;
      From : constant Pop_Group_Handle :=
               Get_By_Tag (Config.Config_Name);
   begin
      for Infl_Config of Config.Child ("influences") loop
         declare
            To : constant Pop_Group_Handle :=
                   Get_By_Tag (Infl_Config.Config_Name);
            Value : constant Real :=
                      Real (Float'(Infl_Config.Value));
         begin
            Concorde.Handles.Group_Influence.Create
              (From, To, Value);
         end;
      end loop;
   end Configure_Influence;

   -------------------------
   -- Configure_Pop_Group --
   -------------------------

   procedure Configure_Pop_Group
     (Config : Tropos.Configuration)
   is

      procedure Metric
        (Suffix : String;
         Value  : Concorde.Db.Node_Value_Type := Concorde.Db.Rating);

      ------------
      -- Metric --
      ------------

      procedure Metric
        (Suffix : String;
         Value  : Concorde.Db.Node_Value_Type := Concorde.Db.Rating)
      is
         Tag : constant String :=
                 Config.Config_Name
                 & (if Suffix = "" then "" else "-" & Suffix);
      begin
         Concorde.Handles.Metric.Create
           (Content    => Value,
            Identifier => Concorde.Identifiers.Next_Identifier,
            Tag        => Tag);
      end Metric;

      Is_Wealth_Group : constant Boolean :=
                          Config.Get ("wealth-group");
      Proportion      : constant Real :=
           Real (Long_Float'(Config.Get ("proportion", 0.0)));

   begin

      if Is_Wealth_Group then
         Concorde.Handles.Wealth_Group.Create
           (Proportion => Proportion,
            Priority   => Config.Get ("priority", Natural'Last),
            Tag        => Config.Config_Name);
      else
         Concorde.Handles.Pop_Group.Create
           (Tag        => Config.Config_Name,
            Proportion => Proportion);
      end if;

      Metric ("population", Concorde.Db.Quantity);
      Metric ("proportion");
      Metric ("income");
      Metric ("");

      if Is_Wealth_Group then
         Metric ("base-income", Concorde.Db.Money);
      end if;

      for Demand_Config of Config.Child ("demand") loop
         Configure_Pop_Group_Metric
           (Pop_Group_Tag => Config.Config_Name,
            Metric_Tag    => "demand",
            Commodity_Tag => Demand_Config.Config_Name,
            Expression    => Demand_Config.Value);

         Concorde.Handles.Pop_Group_Demand.Create
           (Pop_Group =>
              Concorde.Handles.Pop_Group.Get_By_Tag (Config.Config_Name),
            Commodity =>
              Concorde.Handles.Commodity.Get_By_Tag
                (Demand_Config.Config_Name));

         Metric
           (Demand_Config.Config_Name & "-recv",
            Concorde.Db.Quantity);

         declare
            Demand_Tag : constant String :=
                           Config.Config_Name & "-"
                           & Demand_Config.Config_Name & "-demand";
            Receive_Tag : constant String :=
                           Config.Config_Name & "-"
                           & Demand_Config.Config_Name & "-recv";
         begin
            Concorde.Handles.Effect.Create
              (Identifier => Identifiers.Next_Identifier,
               Expression =>
                 "1 - " & Demand_Tag & " / max 0.1 " & Receive_Tag,
               Node       =>
                 Concorde.Handles.Node.Get_By_Tag (Receive_Tag),
               To         =>
                 Concorde.Handles.Node.Get_By_Tag (Config.Config_Name));
         end;
      end loop;

      for Demand_Config of Config.Child ("desire") loop
         Configure_Pop_Group_Metric
           (Pop_Group_Tag => Config.Config_Name,
            Metric_Tag    => "desire",
            Commodity_Tag => Demand_Config.Config_Name,
            Expression    => Demand_Config.Value);
      end loop;

   end Configure_Pop_Group;

   --------------------------------
   -- Configure_Pop_Group_Metric --
   --------------------------------

   procedure Configure_Pop_Group_Metric
     (Pop_Group_Tag : String;
      Metric_Tag    : String;
      Commodity_Tag : String;
      Expression    : String)
   is
      Tag : constant String :=
              Pop_Group_Tag & "-" & Commodity_Tag & "-" & Metric_Tag;
   begin
      Concorde.Configure.Metrics.Add_Calculation
        (Tag        => Tag,
         Content    => Concorde.Db.Quantity,
         Expression => Expression);
      Concorde.Configure.Metrics.Update_Metric
        (Metric_Tag    => Commodity_Tag & "-" & Metric_Tag,
         Calculation   => Tag);
   end Configure_Pop_Group_Metric;

   --------------------------
   -- Configure_Pop_Groups --
   --------------------------

   procedure Configure_Pop_Groups
     (Scenario_Name : String)
   is
   begin
      Load_Scenario_Files
        (Scenario_Name   => Scenario_Name,
         Directory_Name  => "pop-groups",
         File_Class_Name => "group",
         Process         => Configure_Pop_Group'Access);
      Load_Scenario_Files
        (Scenario_Name   => Scenario_Name,
         Directory_Name  => "pop-groups",
         File_Class_Name => "group",
         Process         => Configure_Influence'Access);
   end Configure_Pop_Groups;

end Concorde.Configure.Pop_Groups;
