with Concorde.Money;

with Concorde.Db.Consumer_Good;
with Concorde.Db.Pop_Group;
with Concorde.Db.Pop_Group_Needs;

package body Concorde.Configure.Pop_Groups is

   procedure Configure_Pop_Group
     (Config : Tropos.Configuration);

   -------------------------
   -- Configure_Pop_Group --
   -------------------------

   procedure Configure_Pop_Group
     (Config : Tropos.Configuration)
   is
      Price : constant Concorde.Money.Price_Type :=
                Configure_Price (Config, "salary");
      Consumer_Quality : constant Positive :=
                           Config.Child ("quality").Get ("consumer");
      Service_Quality  : constant Positive :=
                           Config.Child ("quality").Get ("service");
      Pop_Group : constant Concorde.Db.Pop_Group_Reference :=
                           Concorde.Db.Pop_Group.Create
                             (Available        => True,
                              Initial_Price    => Price,
                              Mass             => 1.0,
                              Density          => 0.0,
                              Tag              => Config.Config_Name,
                              Consumer_Quality => Consumer_Quality,
                              Service_Quality  => Service_Quality,
                              Salary           => Price);

   begin

      for Consumer of
        Concorde.Db.Consumer_Good.Select_By_Quality
          (Consumer_Quality)
      loop
         Concorde.Db.Pop_Group_Needs.Create
           (Pop_Group => Pop_Group,
            Commodity => Consumer.Get_Commodity_Reference);
      end loop;

   end Configure_Pop_Group;

   --------------------------
   -- Configure_Pop_Groups --
   --------------------------

   procedure Configure_Pop_Groups
     (Scenario_Name : String)
   is
   begin
      Load_Scenario_Files
        (Scenario_Name   => Scenario_Name,
         Directory_Name  => "poptypes",
         File_Class_Name => "poptype",
         Process         => Configure_Pop_Group'Access);
   end Configure_Pop_Groups;

end Concorde.Configure.Pop_Groups;
