with Concorde.Db;

package Concorde.Facilities is

   function Facility_Class
     (Name : String)
      return Concorde.Handles.Facility_Class_Reference;

   function Get
     (Tag : String)
      return Concorde.Handles.Facility_Reference;

end Concorde.Facilities;
