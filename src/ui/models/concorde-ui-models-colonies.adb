with Concorde.UI.Models.Colonies.Factions;
with Concorde.UI.Models.Colonies.Policies;
with Concorde.UI.Models.Colonies.Pop_Groups;

package body Concorde.UI.Models.Colonies is

   -------------------------
   -- Colony_Policy_Model --
   -------------------------

   function Colony_Policy_Model
     (Colony : Concorde.Handles.Colony.Colony_Handle)
      return Nazar.Models.Table.Nazar_Table_Model
   is
   begin
      return Policies.Model (Colony);
   end Colony_Policy_Model;

   ----------------------------
   -- Colony_Pop_Group_Model --
   ----------------------------

   function Colony_Pop_Group_Model
     (Colony : Concorde.Handles.Colony.Colony_Handle)
      return Nazar.Models.Table.Nazar_Table_Model
   is
   begin
      return Pop_Groups.Model (Colony);
   end Colony_Pop_Group_Model;

   --------------------------
   -- Faction_Colony_Table --
   --------------------------

   function Faction_Colony_Table
     (Faction : Concorde.Handles.Faction.Faction_Handle)
      return Nazar.Models.Table.Nazar_Table_Model
   is
   begin
      return Factions.Model (Faction);
   end Faction_Colony_Table;

end Concorde.UI.Models.Colonies;
