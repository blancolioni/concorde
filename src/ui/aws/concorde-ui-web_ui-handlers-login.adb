with Concorde.Sessions;

package body Concorde.UI.Web_UI.Handlers.Login is

   -------------------
   -- Handle_Create --
   -------------------

   overriding function Handle_Create
     (Handler    : Login_Handler;
      Parameters : Routes.Parameter_Container'Class)
      return State_Interface'Class
   is
      pragma Unreferenced (Handler);
      User_Name : constant String := Parameters.Parameter ("user");
      Password  : constant String := Parameters.Parameter ("password");
      State     : constant State_Interface'Class :=
        Concorde.Sessions.New_Session (User_Name, Password);
   begin
      return State;
   end Handle_Create;

end Concorde.UI.Web_UI.Handlers.Login;
