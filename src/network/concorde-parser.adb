with GCS.Errors;

with Concorde.Parser.Tokens;               use Concorde.Parser.Tokens;
with Concorde.Parser.Lexical;              use Concorde.Parser.Lexical;

with Concorde.Behaviors.Sines;
with Concorde.Symbols;
with Concorde.Values;

package body Concorde.Parser is

   type Precedence_Range is range 1 .. 9;

   type Create_Op_Expr is
     access function (Left, Right : Concorde.Expressions.Expression_Type)
                      return Concorde.Expressions.Expression_Type;

   type Operator_Entry is
      record
         Is_Operator : Boolean := False;
         Precedence  : Precedence_Range := 9;
         Create      : Create_Op_Expr := null;
      end record;

   Ops : constant array (Token) of Operator_Entry :=
           (Tok_Plus     => (True, 4, Concorde.Expressions."+"'Access),
            Tok_Minus    => (True, 4, Concorde.Expressions."-"'Access),
            Tok_Asterisk => (True, 3, Concorde.Expressions."*"'Access),
            Tok_Slash    => (True, 3, Concorde.Expressions."/"'Access),
            Tok_Power    => (True, 2, Concorde.Expressions."**"'Access),
--              Tok_EQ       => (True, 6),
--              Tok_NE       => (True, 6),
--              Tok_GE       => (True, 6),
--              Tok_LE       => (True, 6),
--              Tok_GT       => (True, 6),
--              Tok_LT       => (True, 6),
            others       => <>);

   type Empty_Environment_Type is
     new Concorde.Values.Environment_Interface with null record;

   overriding function Get
     (Environment    : Empty_Environment_Type;
      Name           : Concorde.Symbols.Symbol_Id;
      With_Delay     : Real_Time := 0.0;
      With_Smoothing : Real_Time := 0.0)
      return Concorde.Values.Value_Interface'Class;

   function Parse_Application
     return Concorde.Expressions.Expression_Type;

   function Parse_Atomic_Expression
     return Concorde.Expressions.Expression_Type;

   function Parse_Operator_Expression
     (Precedence : Precedence_Range)
      return Concorde.Expressions.Expression_Type;

   function Parse_Expression
     return Concorde.Expressions.Expression_Type;

   function At_Expression return Boolean
   is (Tok in Tok_Integer_Constant | Tok_Float_Constant
       | Tok_String_Constant | Tok_Character_Constant
       | Tok_Identifier | Tok_Sin | Tok_Delay | Tok_Smooth
       | Tok_Left_Paren);

   ---------
   -- Get --
   ---------

   overriding function Get
     (Environment    : Empty_Environment_Type;
      Name           : Concorde.Symbols.Symbol_Id;
      With_Delay     : Real_Time := 0.0;
      With_Smoothing : Real_Time := 0.0)
      return Concorde.Values.Value_Interface'Class
   is
      pragma Unreferenced (Environment, With_Smoothing);
      use type Concorde.Symbols.Symbol_Id;
   begin
      if Name = Concorde.Symbols.Get_Symbol ("time") then
         return Concorde.Values.Constant_Value (-Real (With_Delay));
      else
         return raise Constraint_Error with
           "attempt to get value from empty environment";
      end if;
   end Get;

   -----------------------
   -- Parse_Application --
   -----------------------

   function Parse_Application
     return Concorde.Expressions.Expression_Type
   is
      Result : Concorde.Expressions.Expression_Type :=
                 Parse_Atomic_Expression;
   begin
      while At_Expression loop
         declare
            Argument : constant Concorde.Expressions.Expression_Type :=
                         Parse_Atomic_Expression;
         begin
            Result := Result.Apply (Argument);
         end;
      end loop;
      return Result;
   end Parse_Application;

   -----------------------------
   -- Parse_Atomic_Expression --
   -----------------------------

   function Parse_Atomic_Expression
     return Concorde.Expressions.Expression_Type
   is

      use Concorde.Expressions;

      Negated : Boolean := False;

      function Result
        (Expr : Concorde.Expressions.Expression_Type)
         return Concorde.Expressions.Expression_Type
      is (if not Negated then Expr
          else (Constant_Expression (-1.0) * Expr));

   begin
      if Tok = Tok_Minus then
         Negated := True;
         Scan;
      elsif Tok = Tok_Plus then
         Scan;
      end if;

      if Tok = Tok_Float_Constant or else Tok = Tok_Integer_Constant then
         declare
            Value : Real := Real'Value (Tok_Text);
         begin
            Scan;
            if Tok = Tok_Percent then
               Value := Value / 100.0;
               Scan;
            end if;
            return Result (Constant_Expression (Value));
         end;
      elsif Tok = Tok_Identifier then
         declare
            Name : constant String := Tok_Text;
         begin
            Scan;
            return Result (Identifier_Expression (Name));
         end;
      elsif Tok = Tok_Left_Paren then
         Scan;
         declare
            Expr : constant Expression_Type :=
                     Result (Parse_Expression);
         begin
            if Tok = Tok_Right_Paren then
               Scan;
            else
               Error ("missing ')'");
            end if;
            return Expr;
         end;
      elsif Tok = Tok_Delay or else Tok = Tok_Smooth then
         declare
            Smooth : constant Boolean := Tok = Tok_Smooth;
         begin
            Scan;
            if Tok = Tok_Integer_Constant then
               declare
                  Days : constant Natural :=
                           Natural'Value (Tok_Text);
               begin
                  Scan;
                  declare
                     Age   : constant Real_Time := Real_Time (Days);
                     Inner : constant Expression_Type :=
                               Parse_Atomic_Expression;
                     Expr          : constant Expression_Type :=
                                       (if Smooth
                                        then Smooth_Expression (Age, Inner)
                                        else Delay_Expression (Age, Inner));
                  begin
                     return Result (Expr);
                  end;
               end;
            else
               Error ("missing day count");
               while Tok_Indent > 1 loop
                  Scan;
               end loop;
               return Concorde.Expressions.Value_Expression
                 (Concorde.Values.Constant_Value (0.0));
            end if;
         end;
      elsif Tok = Tok_Sin then
         Scan;
         declare
            Wavelength : Non_Negative_Real := 1.0;
            Amplitude  : Non_Negative_Real := 1.0;
            Phase      : Non_Negative_Real := 0.0;
         begin
            if Tok = Tok_Float_Constant
              or else Tok = Tok_Integer_Constant
            then
               Wavelength := Real'Value (Tok_Text);
               Scan;
               if Tok = Tok_Float_Constant
                 or else Tok = Tok_Integer_Constant
               then
                  Amplitude := Real'Value (Tok_Text);
                  Scan;
                  if Tok = Tok_Float_Constant
                    or else Tok = Tok_Integer_Constant
                  then
                     Phase := Real'Value (Tok_Text);
                     Scan;
                  end if;
               end if;
            end if;

            return Result
              (Behavior_Expression
                 (Concorde.Behaviors.Sines.Sine_Behavior
                      (Frequency => 1.0 / Wavelength,
                       Amplitude => Amplitude,
                       Phase     => Phase)));
         end;

      else
         Error ("missing expression at "
                & Tok'Image
                & " [" & Tok_Text & "]");
         return Concorde.Expressions.Value_Expression
           (Concorde.Values.Constant_Value (0.0));
      end if;
   end Parse_Atomic_Expression;

   ----------------------
   -- Parse_Expression --
   ----------------------

   function Parse_Expression return Concorde.Expressions.Expression_Type is
   begin
      return Parse_Operator_Expression (Precedence_Range'Last);
   end Parse_Expression;

   ----------------------
   -- Parse_Expression --
   ----------------------

   function Parse_Expression
     (Source : String)
      return Concorde.Expressions.Expression_Type
   is
   begin
      GCS.Errors.Clear_Errors;
      Open_String (Source);
      return Expression : constant Concorde.Expressions.Expression_Type :=
        Parse_Expression
      do
         if GCS.Errors.Has_Errors then
            Close;
            raise Constraint_Error with
              "errors in expression: " & Source;
         end if;
         Close;
      end return;
   end Parse_Expression;

   -------------------------------
   -- Parse_Operator_Expression --
   -------------------------------

   function Parse_Operator_Expression
     (Precedence : Precedence_Range)
      return Concorde.Expressions.Expression_Type
   is

      function Parse_Child return Concorde.Expressions.Expression_Type
      is (if Precedence = Precedence_Range'First
          then Parse_Application
          else Parse_Operator_Expression (Precedence - 1));

      Left : constant Concorde.Expressions.Expression_Type :=
               Parse_Child;
      Result : Concorde.Expressions.Expression_Type := Left;
   begin
      while Ops (Tok).Is_Operator
        and then Ops (Tok).Precedence = Precedence
      loop
         declare
            Op_Tok : constant Token := Tok;
            Right  : Concorde.Expressions.Expression_Type;
         begin
            Scan;
            Right := Parse_Child;
            Result := Ops (Op_Tok).Create (Result, Right);
         end;
      end loop;
      return Result;
   end Parse_Operator_Expression;

end Concorde.Parser;
