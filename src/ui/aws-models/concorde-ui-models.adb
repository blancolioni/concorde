with Ada.Text_IO;

package body Concorde.UI.Models is

   -----------
   -- Error --
   -----------

   function Error
     (Model   : in out Root_Concorde_Model'class;
      State   : in out State_Interface'Class;
      Client  : Client_Id;
      Request : Concorde.Json.Json_Value'Class;
      Message : String)
      return Concorde.Json.Json_Value'Class
   is
      pragma Unreferenced (State);
      use Ada.Text_IO;
   begin
      Put_Line (Standard_Error,
                "error in model " & Model.Name & " client" & Client'Image);
      Put_Line ("request: " & Request.Image);
      Put_Line (Standard_Error,
                "message: " & Message);
      return Response : Concorde.Json.Json_Object do
         Response.Set_Property ("error", Message);
      end return;

   end Error;

end Concorde.UI.Models;
