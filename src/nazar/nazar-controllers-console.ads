with Nazar.Signals;

with Nazar.Models.Console;
with Nazar.Views.Console;

package Nazar.Controllers.Console is

   subtype Controller_Model is
     Nazar.Models.Console.Root_Console_Model'Class;

   subtype Controller_View is
     Nazar.Views.Console.Console_View_Interface'Class;

   type Root_Console_Controller is
     new Nazar.Signals.User_Data_Interface with private;

   procedure Start_Console
     (Controller : in out Root_Console_Controller;
      Model      : not null access Controller_Model;
      View       : not null access Controller_View);

private

   type Model_Access is access all Controller_Model;
   type View_Access is access all Controller_View;

   type Root_Console_Controller is new Nazar.Signals.User_Data_Interface with
      record
         Model : Model_Access;
         View  : View_Access;
      end record;

end Nazar.Controllers.Console;
