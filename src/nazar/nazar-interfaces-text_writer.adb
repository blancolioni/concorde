package body Nazar.Interfaces.Text_Writer is

   --------------
   -- New_Line --
   --------------

   procedure New_Line (Writer : in out Text_Writer_Interface'Class) is
   begin
      Writer.New_Line (Standard_Text);
   end New_Line;

   ---------
   -- Put --
   ---------

   procedure Put (Writer : in out Text_Writer_Interface'Class;
                  Text   : String)
   is
   begin
      Writer.Put (Standard_Text, Text);
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line
     (Writer : in out Text_Writer_Interface'Class;
      Class  : Text_Class;
      Line   : String)
   is
   begin
      Writer.Put (Class, Line);
      Writer.New_Line (Class);
   end Put_Line;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line
     (Writer : in out Text_Writer_Interface'Class;
      Line   : String)
   is
   begin
      Writer.Put_Line (Standard_Text, Line);
   end Put_Line;

end Nazar.Interfaces.Text_Writer;
