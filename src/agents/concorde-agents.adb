with Concorde.Commodities;
with Concorde.Logging;
with Concorde.Quantities;
with Concorde.Real_Images;
with Concorde.Stock;

with Concorde.Db.Account;

package body Concorde.Agents is

   --------------
   -- Add_Cash --
   --------------

   procedure Add_Cash
     (Agent : Concorde.Db.Agent.Agent_Type;
      Cash  : Concorde.Money.Money_Type)
   is
      use type Concorde.Money.Money_Type;
      Account : constant Concorde.Db.Account.Account_Type :=
                  Concorde.Db.Account.Get (Agent.Account);
   begin
      Concorde.Db.Account.Update_Account (Agent.Account)
        .Set_Cash (Account.Cash + Cash)
        .Done;
   end Add_Cash;

   --------------
   -- Add_Cash --
   --------------

   procedure Add_Cash
     (Account : Concorde.Db.Account_Reference;
      Cash    : Concorde.Money.Money_Type)
   is
      use type Concorde.Money.Money_Type;
      Rec : constant Concorde.Db.Account.Account_Type :=
              Concorde.Db.Account.Get (Account);
   begin
      Concorde.Db.Account.Update_Account (Account)
        .Set_Cash (Rec.Cash + Cash)
        .Done;
   end Add_Cash;

   ----------
   -- Cash --
   ----------

   function Cash
     (Account : Concorde.Db.Account_Reference)
      return Concorde.Money.Money_Type
   is
   begin
      return Concorde.Db.Account.Get (Account).Cash;
   end Cash;

   ----------
   -- Cash --
   ----------

   function Cash
     (Agent : Concorde.Db.Agent.Agent_Type)
      return Concorde.Money.Money_Type
   is
   begin
      return Cash (Agent.Account);
   end Cash;

   ---------------
   -- Log_Agent --
   ---------------

   procedure Log_Agent
     (Agent   : Concorde.Db.Agent_Reference;
      Message : String)
   is
   begin
      Concorde.Logging.Log
        (Actor    => "Agent" & Concorde.Db.To_String (Agent),
         Location => "",
         Category => "",
         Message  => Message);
   end Log_Agent;

   -----------------
   -- Move_Assets --
   -----------------

   procedure Move_Assets
     (From     : Concorde.Db.Agent.Agent_Type;
      To       : Concorde.Db.Agent.Agent_Type;
      Fraction : Unit_Real)
   is
      use Concorde.Money;

      From_Account : constant Concorde.Db.Account.Account_Type :=
                       Concorde.Db.Account.Get (From.Account);
      To_Account   : constant Concorde.Db.Account.Account_Type :=
                       Concorde.Db.Account.Get (To.Account);
      Transfer_Cash : constant Money_Type :=
                        Adjust (From_Account.Cash, Fraction);
      From_Stock    : Concorde.Commodities.Stock_Type;

      procedure Transfer_Stock
        (Commodity : Concorde.Db.Commodity_Reference;
         Quantity  : Concorde.Quantities.Quantity_Type;
         Value     : Concorde.Money.Money_Type);

      --------------------
      -- Transfer_Stock --
      --------------------

      procedure Transfer_Stock
        (Commodity : Concorde.Db.Commodity_Reference;
         Quantity  : Concorde.Quantities.Quantity_Type;
         Value     : Concorde.Money.Money_Type)
      is
         use Concorde.Quantities;
         Transfer_Quantity : constant Quantity_Type :=
                               Scale (Quantity, Fraction);
         Transfer_Value    : constant Money_Type :=
                               Adjust (Value, Fraction);
      begin
         Log_Agent
           (From.Get_Agent_Reference,
            "transferring " & Show (Transfer_Quantity)
            & " " & Concorde.Commodities.Local_Name (Commodity)
            & " of " & Show (Quantity));
         Concorde.Stock.Remove_Stock
           (From.Get_Has_Stock_Reference, Commodity, Transfer_Quantity);
         Concorde.Stock.Add_Stock
           (To.Get_Has_Stock_Reference,
            Commodity, Transfer_Quantity, Transfer_Value);
      end Transfer_Stock;

   begin

      Log_Agent (From.Get_Agent_Reference,
                 "transferring "
                 & Concorde.Real_Images.Approximate_Image (Fraction * 100.0)
                 & "% to agent"
                 & Concorde.Db.To_String
                   (To.Get_Agent_Reference));

      Concorde.Db.Account.Update_Account (From.Account)
        .Set_Cash (From_Account.Cash - Transfer_Cash)
        .Done;

      Concorde.Db.Account.Update_Account (To.Account)
        .Set_Cash (To_Account.Cash + Transfer_Cash)
        .Done;

      From_Stock.Load (From.Get_Has_Stock_Reference);
      From_Stock.Iterate (Transfer_Stock'Access);

   exception
      when others =>
         Log_Agent (From.Get_Agent_Reference,
                    "exception during transfer");
         raise;
--        for Stock of
--          Concorde.Db.Stock_Item.Select_By_Has_Stock (From.Reference)
--        loop
--           declare
--              use Concorde.Quantities;
--              Current_Quantity : constant Quantity_Type :=
--                                   Stock.Quantity;
--              Transfer_Quantity : constant Quantity_Type :=
--                                    Scale (Current_Quantity, Fraction);
--              Current_Value     : constant Money_Type :=
--                                    Stock.Value;
--              Transfer_Value    : constant Money_Type :=
--                                    Adjust (Current_Value, Fraction);
--           begin
--              Stock.Set_Quantity (Current_Quantity - Transfer_Quantity);
--              Stock.Set_Value (Current_Value - Transfer_Value);
--              Concorde.Stock.Add_Stock
--                (To.Reference, Stock.Commodity,
--                 Transfer_Quantity, Transfer_Value);
--           end;
--        end loop;
   end Move_Assets;

   -----------------
   -- Remove_Cash --
   -----------------

   procedure Remove_Cash
     (Account : Concorde.Db.Account_Reference;
      Cash    : Concorde.Money.Money_Type)
   is
      use type Concorde.Money.Money_Type;
      Rec : constant Concorde.Db.Account.Account_Type :=
              Concorde.Db.Account.Get (Account);
   begin
      Concorde.Db.Account.Update_Account (Account)
        .Set_Cash (Rec.Cash - Cash)
        .Done;

   end Remove_Cash;

end Concorde.Agents;
