with Gtk.Enums;

package body Nazar.Views.Gtk_Views.Box is

   ------------
   -- Append --
   ------------

   overriding procedure Append
     (View  : in out Nazar_Gtk_Box_View_Record;
      Child : not null access Nazar_View_Record'Class)
   is
   begin
      View.Box.Pack_Start
        (Nazar_Gtk_View (Child).Widget);
   end Append;

   -------------------
   -- Model_Changed --
   -------------------

   overriding procedure Model_Changed
     (View : in out Nazar_Gtk_Box_View_Record)
   is null;

   -------------------------------
   -- Nazar_Gtk_Box_View_Create --
   -------------------------------

   function Nazar_Gtk_Box_View_Create
     (Orientation : Nazar.Views.Orientable.Nazar_Orientation)
      return Nazar_View
   is
      use all type Nazar.Views.Orientable.Nazar_Orientation;
      View : constant Nazar_Gtk_Box_View :=
        new Nazar_Gtk_Box_View_Record;
      Gtk_Orientation : constant Gtk.Enums.Gtk_Orientation :=
        (case Orientation is
            when Horizontal => Gtk.Enums.Orientation_Horizontal,
            when Vertical   => Gtk.Enums.Orientation_Vertical);
   begin
      View.Box :=
        Gtk.Box.Gtk_Box_New
          (Orientation => Gtk_Orientation,
           Spacing     => 1);
      View.Initialize (View.Box);
      return Nazar_View (View);
   end Nazar_Gtk_Box_View_Create;

   ----------------------------
   -- Nazar_Gtk_Box_View_New --
   ----------------------------

   function Nazar_Gtk_Box_View_New
     (Model       : not null access
        Nazar.Models.Layout.Root_Layout_Model'Class;
      Orientation : Nazar.Views.Orientable.Nazar_Orientation)
      return Nazar_Gtk_Box_View
   is
      View : constant Nazar_Gtk_Box_View :=
        Nazar_Gtk_Box_View (Nazar_Gtk_Box_View_Create (Orientation));
   begin
      View.Set_Model (Model);
      return View;
   end Nazar_Gtk_Box_View_New;

   ---------------------
   -- Set_Orientation --
   ---------------------

   overriding procedure Set_Orientation
     (View        : in out Nazar_Gtk_Box_View_Record;
      Orientation : Nazar.Views.Orientable.Nazar_Orientation)
   is
      use all type Nazar.Views.Orientable.Nazar_Orientation;
   begin
      View.Orientation := Orientation;
      View.Box.Set_Orientation
        (case Orientation is
            when Horizontal => Gtk.Enums.Orientation_Horizontal,
            when Vertical   => Gtk.Enums.Orientation_Vertical);
   end Set_Orientation;

end Nazar.Views.Gtk_Views.Box;
