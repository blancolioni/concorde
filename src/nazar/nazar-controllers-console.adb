package body Nazar.Controllers.Console is

   procedure Handle_Command
     (Command_Line : String;
      User_Data    : Nazar.Signals.User_Data_Interface'Class);

   --------------------
   -- Handle_Command --
   --------------------

   procedure Handle_Command
     (Command_Line : String;
      User_Data    : Nazar.Signals.User_Data_Interface'Class)
   is
      Controller : Root_Console_Controller'Class renames
        Root_Console_Controller'Class (User_Data);
   begin
      Controller.Model.Execute_Command_Line (Command_Line);
      Controller.View.Set_Prompt_Text
        (Controller.Model.Get_Prompt_Text);
   end Handle_Command;

   -------------------
   -- Start_Console --
   -------------------

   procedure Start_Console
     (Controller : in out Root_Console_Controller;
      Model      : not null access Controller_Model;
      View       : not null access Controller_View)
   is
   begin
      Controller.Model := Model_Access (Model);
      Controller.View  := View_Access (View);
      Controller.View.Set_Prompt_Text (Model.Get_Prompt_Text);
      View.On_Command (Handle_Command'Access, Controller);
      View.Show;
   end Start_Console;

end Nazar.Controllers.Console;